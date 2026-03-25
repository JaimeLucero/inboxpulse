"""Vercel serverless function — Google Analytics OAuth callback.
Uses Firestore REST API directly (no firebase-admin gRPC) for fast cold starts.
"""

from http.server import BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime, timezone
import json
import os
import requests

_PROJECT = "inboxpulse-a6458"
_FIRESTORE = f"https://firestore.googleapis.com/v1/projects/{_PROJECT}/databases/(default)/documents"


# ── Auth helpers ──────────────────────────────────────────────────────────────

def _service_account_token() -> str:
    """Mint a short-lived access token from the service account."""
    from google.oauth2 import service_account
    import google.auth.transport.requests as g_requests
    sa = json.loads(os.environ.get("FIREBASE_SERVICE_ACCOUNT", "{}"))
    creds = service_account.Credentials.from_service_account_info(
        sa, scopes=["https://www.googleapis.com/auth/datastore"]
    )
    creds.refresh(g_requests.Request())
    return creds.token


def _verify_id_token(id_token: str) -> str | None:
    """Verify a Firebase ID token via REST. Returns uid or None."""
    api_key = os.environ.get("FIREBASE_WEB_API_KEY", "")
    resp = requests.post(
        f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={api_key}",
        json={"idToken": id_token},
        timeout=5,
    ).json()
    users = resp.get("users", [])
    return users[0]["localId"] if users else None


# ── Firestore REST helpers ────────────────────────────────────────────────────

def _fs_query(collection: str, field: str, value: str, token: str) -> list:
    resp = requests.post(
        f"{_FIRESTORE}:runQuery",
        headers={"Authorization": f"Bearer {token}"},
        json={"structuredQuery": {
            "from": [{"collectionId": collection}],
            "where": {"fieldFilter": {
                "field": {"fieldPath": field},
                "op": "EQUAL",
                "value": {"stringValue": value},
            }},
        }},
        timeout=8,
    ).json()
    return [r["document"] for r in resp if "document" in r]


def _fs_delete(doc_name: str, token: str):
    requests.delete(
        f"https://firestore.googleapis.com/v1/{doc_name}",
        headers={"Authorization": f"Bearer {token}"},
        timeout=5,
    )


def _fs_add(collection: str, data: dict, token: str):
    requests.post(
        f"{_FIRESTORE}/{collection}",
        headers={"Authorization": f"Bearer {token}"},
        json={"fields": _to_fs(data)},
        timeout=8,
    )


def _to_fs(data: dict) -> dict:
    """Convert a Python dict to Firestore REST field format."""
    out = {}
    for k, v in data.items():
        if v is None:
            out[k] = {"nullValue": None}
        elif isinstance(v, bool):
            out[k] = {"booleanValue": v}
        elif isinstance(v, int):
            out[k] = {"integerValue": str(v)}
        elif isinstance(v, float):
            out[k] = {"doubleValue": v}
        elif isinstance(v, str):
            out[k] = {"stringValue": v}
        elif isinstance(v, list):
            out[k] = {"arrayValue": {"values": [_to_fs_val(i) for i in v]}}
        elif isinstance(v, dict):
            out[k] = {"mapValue": {"fields": _to_fs(v)}}
    return out


def _to_fs_val(v) -> dict:
    if v is None:       return {"nullValue": None}
    if isinstance(v, bool):  return {"booleanValue": v}
    if isinstance(v, int):   return {"integerValue": str(v)}
    if isinstance(v, float): return {"doubleValue": v}
    if isinstance(v, str):   return {"stringValue": v}
    if isinstance(v, dict):  return {"mapValue": {"fields": _to_fs(v)}}
    if isinstance(v, list):  return {"arrayValue": {"values": [_to_fs_val(i) for i in v]}}
    return {"stringValue": str(v)}


# ── GA helpers ────────────────────────────────────────────────────────────────

def _list_properties(access_token: str) -> list:
    resp = requests.get(
        "https://analyticsadmin.googleapis.com/v1beta/accountSummaries",
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=8,
    ).json()
    props = []
    for account in resp.get("accountSummaries", []):
        for prop in account.get("propertySummaries", []):
            props.append({"id": prop.get("property", ""), "name": prop.get("displayName", "")})
    return props


# ── Handler ───────────────────────────────────────────────────────────────────

class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        app_url = os.environ.get("APP_URL", "https://inboxpulse-beta.vercel.app")
        params = parse_qs(urlparse(self.path).query)
        code = (params.get("code") or [None])[0]
        id_token = (params.get("state") or [None])[0]

        if not code or not id_token:
            return self._redirect(f"{app_url}?ga=error&reason=missing_params")

        uid = _verify_id_token(id_token)
        if not uid:
            return self._redirect(f"{app_url}?ga=error&reason=invalid_token")

        # Exchange code for OAuth tokens
        callback_url = os.environ.get("GA_CALLBACK_URL", f"{app_url}/api/ga_callback")
        token_resp = requests.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": code,
                "client_id": os.environ.get("GOOGLE_OAUTH_CLIENT_ID", ""),
                "client_secret": os.environ.get("GOOGLE_OAUTH_CLIENT_SECRET", ""),
                "redirect_uri": callback_url,
                "grant_type": "authorization_code",
            },
            timeout=8,
        ).json()

        access_token = token_resp.get("access_token")
        refresh_token = token_resp.get("refresh_token")
        if not access_token:
            return self._redirect(f"{app_url}?ga=error&reason=token_exchange")

        properties = _list_properties(access_token)

        # Write to Firestore via REST
        fs_token = _service_account_token()
        for doc in _fs_query("ga_connections", "userId", uid, fs_token):
            _fs_delete(doc["name"], fs_token)

        _fs_add("ga_connections", {
            "userId": uid,
            "refreshToken": refresh_token,
            "accessToken": access_token,
            "properties": properties,
            "propertyId": None,
            "propertyName": None,
            "connectedAt": datetime.now(timezone.utc).isoformat(),
        }, fs_token)

        self._redirect(f"{app_url}?ga=connected")

    def _redirect(self, url: str):
        self.send_response(302)
        self.send_header("Location", url)
        self.end_headers()

    def log_message(self, *args):
        pass
