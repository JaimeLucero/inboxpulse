"""Vercel serverless function — Google Analytics OAuth callback."""

from http.server import BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime, timezone
import json
import os

import requests
import firebase_admin
from firebase_admin import credentials, auth, firestore

# Lazy-init Firebase Admin (persists across warm invocations)
_initialized = False


def _init_firebase():
    global _initialized
    if not _initialized:
        service_account = json.loads(os.environ.get("FIREBASE_SERVICE_ACCOUNT", "{}"))
        cred = credentials.Certificate(service_account)
        firebase_admin.initialize_app(cred)
        _initialized = True


def _list_properties(access_token: str) -> list:
    resp = requests.get(
        "https://analyticsadmin.googleapis.com/v1beta/accountSummaries",
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=10,
    ).json()
    props = []
    for account in resp.get("accountSummaries", []):
        for prop in account.get("propertySummaries", []):
            props.append({
                "id": prop.get("property", ""),
                "name": prop.get("displayName", ""),
            })
    return props


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        app_url = os.environ.get("APP_URL", "https://inboxpulse.vercel.app")

        params = parse_qs(urlparse(self.path).query)
        code = (params.get("code") or [None])[0]
        id_token = (params.get("state") or [None])[0]

        if not code or not id_token:
            return self._redirect(f"{app_url}?ga=error&reason=missing_params")

        _init_firebase()

        # Verify Firebase ID token → get uid
        try:
            uid = auth.verify_id_token(id_token)["uid"]
        except Exception:
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
            timeout=10,
        ).json()

        access_token = token_resp.get("access_token")
        refresh_token = token_resp.get("refresh_token")

        if not access_token:
            return self._redirect(f"{app_url}?ga=error&reason=token_exchange")

        # Fetch GA4 property list
        properties = _list_properties(access_token)

        # Upsert ga_connections document
        db = firestore.client()
        for doc in db.collection("ga_connections").where("userId", "==", uid).stream():
            doc.reference.delete()

        db.collection("ga_connections").add({
            "userId": uid,
            "refreshToken": refresh_token,
            "accessToken": access_token,
            "properties": properties,
            "propertyId": None,
            "propertyName": None,
            "connectedAt": datetime.now(timezone.utc),
        })

        self._redirect(f"{app_url}?ga=connected")

    def _redirect(self, url: str):
        self.send_response(302)
        self.send_header("Location", url)
        self.end_headers()

    def log_message(self, *args):
        pass  # silence default stdout logging
