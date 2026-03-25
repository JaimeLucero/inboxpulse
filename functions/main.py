import os
import stripe
import resend
from datetime import datetime, timedelta, timezone

from firebase_functions import https_fn, scheduler_fn
from firebase_admin import initialize_app, auth, firestore
from flask import redirect

initialize_app()

resend.api_key = os.environ.get("RESEND_API_KEY", "")
stripe.api_key = None  # Set per-user from stripe_accounts


# ── Stripe OAuth callback ──────────────────────────────────────────────────────

@https_fn.on_request()
def stripe_callback(req: https_fn.Request) -> https_fn.Response:
    """Exchanges Stripe OAuth code for stripe_user_id and saves to Firestore."""
    code = req.args.get("code")
    id_token = req.args.get("state")

    if not code or not id_token:
        return https_fn.Response("Missing code or state", status=400)

    try:
        decoded = auth.verify_id_token(id_token)
        uid = decoded["uid"]
    except Exception:
        return https_fn.Response("Invalid auth token", status=401)

    try:
        platform_secret = os.environ.get("STRIPE_SECRET_KEY", "")
        response = stripe.OAuth.token(  # type: ignore[attr-defined]
            grant_type="authorization_code",
            code=code,
            api_key=platform_secret,
        )
        stripe_user_id = response["stripe_user_id"]
    except stripe.oauth_error.OAuthError as e:  # type: ignore[attr-defined]
        return https_fn.Response(f"Stripe OAuth error: {e}", status=400)

    db = firestore.client()
    # Remove any existing connection for this user first
    existing = db.collection("stripe_accounts").where("userId", "==", uid).stream()
    for doc in existing:
        doc.reference.delete()

    db.collection("stripe_accounts").add({
        "userId": uid,
        "stripeUserId": stripe_user_id,
        "connectedAt": firestore.SERVER_TIMESTAMP,
    })

    # Redirect back to the app
    app_url = os.environ.get("APP_URL", "https://inboxpulse.vercel.app")
    return redirect(f"{app_url}?stripe=connected", code=302)


# ── Preferences ────────────────────────────────────────────────────────────────

@https_fn.on_call()
def save_preferences(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Must be authenticated.")

    uid = req.auth.uid
    data = req.data

    prefs = {
        "userId": uid,
        "frequency": data.get("frequency", "daily"),
        "dayOfWeek": data.get("dayOfWeek", 1),
        "timeOfDay": data.get("timeOfDay", "08:00"),
        "metricsEnabled": data.get("metricsEnabled", {
            "revenue": True, "mrr": True, "new_customers": True,
            "churned_customers": True, "aov": True,
        }),
        "emailEnabled": data.get("emailEnabled", True),
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }

    db = firestore.client()
    existing = list(db.collection("report_preferences").where("userId", "==", uid).limit(1).stream())
    if existing:
        existing[0].reference.update(prefs)
        return {"id": existing[0].id}
    else:
        ref = db.collection("report_preferences").add(prefs)
        return {"id": ref[1].id}


@https_fn.on_call()
def get_preferences(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Must be authenticated.")

    uid = req.auth.uid
    db = firestore.client()
    docs = list(db.collection("report_preferences").where("userId", "==", uid).limit(1).stream())

    if not docs:
        return {}

    data = docs[0].to_dict()
    data.pop("updatedAt", None)  # Remove non-serializable timestamp
    return data


@https_fn.on_call()
def stripe_status(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Must be authenticated.")

    uid = req.auth.uid
    db = firestore.client()
    docs = list(db.collection("stripe_accounts").where("userId", "==", uid).limit(1).stream())
    return {"connected": len(docs) > 0}


# ── Stripe metrics helper ──────────────────────────────────────────────────────

def _fetch_metrics(stripe_user_id: str, period_days: int) -> dict:
    now = datetime.now(timezone.utc)
    start = now - timedelta(days=period_days)
    start_ts = int(start.timestamp())

    metrics: dict = {}

    # Revenue: sum of successful PaymentIntents
    payment_intents = stripe.PaymentIntent.list(
        created={"gte": start_ts},
        stripe_account=stripe_user_id,
        limit=100,
    )
    succeeded = [p for p in payment_intents.auto_paging_iter() if p.status == "succeeded"]
    metrics["revenue"] = sum(p.amount_received for p in succeeded) / 100.0
    metrics["aov"] = (metrics["revenue"] / len(succeeded)) if succeeded else 0.0

    # MRR: sum of active subscription amounts
    subs = stripe.Subscription.list(
        status="active",
        stripe_account=stripe_user_id,
        limit=100,
    )
    mrr = 0.0
    for sub in subs.auto_paging_iter():
        for item in sub["items"]["data"]:
            amount = item["price"]["unit_amount"] or 0
            interval = item["price"]["recurring"]["interval"]
            if interval == "year":
                mrr += amount / 12 / 100
            else:
                mrr += amount / 100
    metrics["mrr"] = mrr

    # New customers
    customers = stripe.Customer.list(
        created={"gte": start_ts},
        stripe_account=stripe_user_id,
        limit=100,
    )
    metrics["new_customers"] = sum(1 for _ in customers.auto_paging_iter())

    # Churned customers (canceled subscriptions)
    canceled = stripe.Subscription.list(
        status="canceled",
        created={"gte": start_ts},
        stripe_account=stripe_user_id,
        limit=100,
    )
    metrics["churned_customers"] = sum(1 for _ in canceled.auto_paging_iter())

    return metrics


# ── Email builder ──────────────────────────────────────────────────────────────

def _build_email_html(metrics: dict, enabled: dict, period_label: str) -> str:
    rows = ""
    labels = {
        "revenue": ("💰", "Revenue"),
        "mrr": ("📈", "MRR"),
        "new_customers": ("🆕", "New Customers"),
        "churned_customers": ("⚠️", "Churned Customers"),
        "aov": ("🛒", "Avg Order Value"),
    }
    for key, (icon, label) in labels.items():
        if not enabled.get(key, False):
            continue
        value = metrics.get(key, 0)
        if key in ("revenue", "mrr", "aov"):
            formatted = f"${value:,.2f}"
        else:
            formatted = str(int(value))
        rows += f"<tr><td style='padding:12px 16px;border-bottom:1px solid #f0f0f0'>{icon} {label}</td><td style='padding:12px 16px;border-bottom:1px solid #f0f0f0;text-align:right;font-weight:600'>{formatted}</td></tr>"

    return f"""
    <html><body style='font-family:sans-serif;max-width:480px;margin:auto;padding:24px'>
    <h2 style='color:#4F46E5'>InboxPulse Report</h2>
    <p style='color:#666'>{period_label}</p>
    <table style='width:100%;border-collapse:collapse;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,0.08)'>
    {rows}
    </table>
    <p style='margin-top:24px;color:#999;font-size:12px'>
    You're receiving this because you set up InboxPulse.
    <a href='https://inboxpulse.vercel.app'>Manage preferences</a>
    </p>
    </body></html>
    """


# ── Scheduled report sender ────────────────────────────────────────────────────

@scheduler_fn.on_schedule(schedule="every 60 minutes")
def send_reports(event: scheduler_fn.ScheduledEvent) -> None:
    """Runs every hour; sends reports to users whose scheduled time matches."""
    db = firestore.client()
    now = datetime.now(timezone.utc)
    current_time = now.strftime("%H:00")
    current_dow = now.isoweekday()  # 1=Monday ... 7=Sunday

    prefs_query = db.collection("report_preferences").where("emailEnabled", "==", True).stream()

    for pref_doc in prefs_query:
        pref = pref_doc.to_dict()
        uid = pref.get("userId")
        frequency = pref.get("frequency", "daily")
        time_of_day = pref.get("timeOfDay", "08:00")

        # Check if this is the right hour
        if time_of_day[:5] != current_time:
            continue

        # For weekly, check day of week
        if frequency == "weekly" and pref.get("dayOfWeek") != current_dow:
            continue

        # Get user email
        try:
            user_record = auth.get_user(uid)
            user_email = user_record.email
        except Exception:
            continue

        # Get stripe account
        stripe_docs = list(db.collection("stripe_accounts").where("userId", "==", uid).limit(1).stream())
        if not stripe_docs:
            continue
        stripe_user_id = stripe_docs[0].to_dict().get("stripeUserId")

        # Fetch metrics
        period_days = 1 if frequency == "daily" else 7
        period_label = f"{'Yesterday' if frequency == 'daily' else 'Last 7 days'} ({now.strftime('%b %d, %Y')})"
        status = "sent"
        error_msg = None
        fetched_metrics: dict = {}

        try:
            fetched_metrics = _fetch_metrics(stripe_user_id, period_days)
            enabled = pref.get("metricsEnabled", {})
            html = _build_email_html(fetched_metrics, enabled, period_label)
            resend.Emails.send({
                "from": "InboxPulse <reports@inboxpulse.app>",
                "to": [user_email],
                "subject": f"Your InboxPulse {'Daily' if frequency == 'daily' else 'Weekly'} Report",
                "html": html,
            })
        except Exception as e:
            status = "failed"
            error_msg = str(e)

        # Log result
        log: dict = {
            "userId": uid,
            "sentAt": firestore.SERVER_TIMESTAMP,
            "metrics": fetched_metrics,
            "status": status,
        }
        if error_msg:
            log["error"] = error_msg

        db.collection("report_logs").add(log)
