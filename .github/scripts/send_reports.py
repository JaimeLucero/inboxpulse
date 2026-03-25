#!/usr/bin/env python3
"""
Sends scheduled Google Analytics reports.
Runs every hour via GitHub Actions; only sends to users whose timeOfDay matches the current UTC hour.
"""

import json
import os
import sys
from datetime import datetime, timedelta, timezone

import requests
import resend
import firebase_admin
from firebase_admin import credentials, auth, firestore

# ── Init ──────────────────────────────────────────────────────────────────────

service_account = json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"])
cred = credentials.Certificate(service_account)
firebase_admin.initialize_app(cred)

resend.api_key = os.environ["RESEND_API_KEY"]

_GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"


# ── GA helpers ────────────────────────────────────────────────────────────────

def refresh_access_token(refresh_token: str) -> str:
    resp = requests.post(_GOOGLE_TOKEN_URL, data={
        "refresh_token": refresh_token,
        "client_id": os.environ["GOOGLE_OAUTH_CLIENT_ID"],
        "client_secret": os.environ["GOOGLE_OAUTH_CLIENT_SECRET"],
        "grant_type": "refresh_token",
    }, timeout=10).json()
    token = resp.get("access_token", "")
    if not token:
        raise RuntimeError(f"Token refresh failed: {resp.get('error_description', resp)}")
    return token


def fetch_ga_metrics(property_id: str, access_token: str, period_days: int) -> dict:
    now = datetime.now(timezone.utc)
    end_date = (now - timedelta(days=1)).strftime("%Y-%m-%d")
    start_date = (now - timedelta(days=period_days)).strftime("%Y-%m-%d")
    prop_id = property_id.replace("properties/", "")

    resp = requests.post(
        f"https://analyticsdata.googleapis.com/v1beta/properties/{prop_id}:runReport",
        headers={"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"},
        json={
            "dateRanges": [{"startDate": start_date, "endDate": end_date}],
            "metrics": [
                {"name": "activeUsers"},
                {"name": "sessions"},
                {"name": "screenPageViews"},
                {"name": "bounceRate"},
                {"name": "averageSessionDuration"},
            ],
        },
        timeout=15,
    ).json()

    totals: dict = {}
    headers = [h["name"] for h in resp.get("metricHeaders", [])]
    for row in resp.get("totals", []):
        for i, cell in enumerate(row.get("metricValues", [])):
            if i < len(headers):
                totals[headers[i]] = float(cell.get("value", 0))

    return {
        "users": int(totals.get("activeUsers", 0)),
        "sessions": int(totals.get("sessions", 0)),
        "pageviews": int(totals.get("screenPageViews", 0)),
        "bounce_rate": round(totals.get("bounceRate", 0) * 100, 1),
        "avg_session_duration": int(totals.get("averageSessionDuration", 0)),
    }


# ── Email ─────────────────────────────────────────────────────────────────────

def _fmt_duration(seconds: int) -> str:
    m, s = divmod(seconds, 60)
    return f"{m}m {s:02d}s"


def build_email_html(metrics: dict, enabled: dict, period_label: str) -> str:
    label_map = {
        "users":                ("👥", "Users",               str(metrics.get("users", 0))),
        "sessions":             ("🔄", "Sessions",            str(metrics.get("sessions", 0))),
        "pageviews":            ("📄", "Pageviews",           str(metrics.get("pageviews", 0))),
        "bounce_rate":          ("↩️", "Bounce Rate",         f"{metrics.get('bounce_rate', 0)}%"),
        "avg_session_duration": ("⏱",  "Avg. Session Duration", _fmt_duration(metrics.get("avg_session_duration", 0))),
    }
    rows = ""
    for key, (icon, label, value) in label_map.items():
        if not enabled.get(key, False):
            continue
        rows += (
            f"<tr>"
            f"<td style='padding:12px 16px;border-bottom:1px solid #1e1e24'>{icon} {label}</td>"
            f"<td style='padding:12px 16px;border-bottom:1px solid #1e1e24;"
            f"text-align:right;font-weight:600;color:#10B981'>{value}</td>"
            f"</tr>"
        )

    return f"""
<html>
<body style='font-family:sans-serif;background:#0B0B0F;color:#e5e5ea;
             max-width:520px;margin:auto;padding:32px 24px'>
  <div style='margin-bottom:24px'>
    <span style='font-size:18px;font-weight:700;color:#10B981'>InboxPulse</span>
    <span style='font-size:18px;font-weight:700;color:#e5e5ea'> Report</span>
  </div>
  <p style='color:#8e8e99;margin:0 0 20px'>{period_label}</p>
  <table style='width:100%;border-collapse:collapse;background:#16161e;
                border-radius:10px;overflow:hidden'>
    {rows}
  </table>
  <p style='margin-top:28px;color:#555;font-size:12px'>
    You're receiving this from InboxPulse. &nbsp;
    <a href='https://inboxpulse.vercel.app' style='color:#10B981'>Manage preferences</a>
  </p>
</body>
</html>
"""


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    db = firestore.client()
    now = datetime.now(timezone.utc)
    current_time = now.strftime("%H:00")
    current_dow = now.isoweekday()  # 1=Mon … 7=Sun

    print(f"[send_reports] {now.isoformat()} — checking for {current_time} UTC (DOW {current_dow})")

    sent = failed = skipped = 0

    for pref_doc in db.collection("report_preferences").where("emailEnabled", "==", True).stream():
        pref = pref_doc.to_dict()
        uid = pref.get("userId")
        frequency = pref.get("frequency", "daily")
        time_of_day = pref.get("timeOfDay", "08:00")

        if time_of_day[:5] != current_time:
            skipped += 1
            continue
        if frequency == "weekly" and pref.get("dayOfWeek") != current_dow:
            skipped += 1
            continue

        try:
            user_email = auth.get_user(uid).email
        except Exception as e:
            print(f"  [skip] uid={uid} — auth lookup failed: {e}")
            skipped += 1
            continue

        ga_docs = list(db.collection("ga_connections").where("userId", "==", uid).limit(1).stream())
        if not ga_docs:
            print(f"  [skip] uid={uid} — no GA connection")
            skipped += 1
            continue

        ga = ga_docs[0].to_dict()
        property_id = ga.get("propertyId")
        refresh_token = ga.get("refreshToken")

        if not property_id or not refresh_token:
            print(f"  [skip] uid={uid} — missing propertyId or refreshToken")
            skipped += 1
            continue

        period_days = 1 if frequency == "daily" else 7
        period_label = (
            f"{'Yesterday' if frequency == 'daily' else 'Last 7 days'} "
            f"({now.strftime('%b %d, %Y')})"
        )
        status = "sent"
        error_msg = None
        fetched_metrics: dict = {}

        try:
            access_token = refresh_access_token(refresh_token)
            fetched_metrics = fetch_ga_metrics(property_id, access_token, period_days)
            enabled = pref.get("metricsEnabled", {})
            html = build_email_html(fetched_metrics, enabled, period_label)
            resend.Emails.send({
                "from": "InboxPulse <reports@inboxpulse.app>",
                "to": [user_email],
                "subject": f"Your InboxPulse {'Daily' if frequency == 'daily' else 'Weekly'} Report",
                "html": html,
            })
            print(f"  [sent] uid={uid} → {user_email}")
            sent += 1
        except Exception as e:
            status = "failed"
            error_msg = str(e)
            print(f"  [fail] uid={uid}: {e}", file=sys.stderr)
            failed += 1

        log: dict = {"userId": uid, "sentAt": datetime.now(timezone.utc),
                     "metrics": fetched_metrics, "status": status}
        if error_msg:
            log["error"] = error_msg
        db.collection("report_logs").add(log)

    print(f"[send_reports] done — sent={sent} failed={failed} skipped={skipped}")


if __name__ == "__main__":
    main()
