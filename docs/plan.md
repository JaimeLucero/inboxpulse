# InboxPulse – Automated Google Analytics Reports Delivered to Your Inbox

## Product Overview

**InboxPulse** is a simple SaaS that connects to your Google Analytics account and emails you the key website metrics you care about – daily or weekly. No dashboards, no complex setup, just numbers in your inbox.

**Target Audience:** Website owners, bloggers, small business owners, marketing managers who want to track traffic, users, and engagement without logging into Google Analytics every day.

**Unique Value:**  
- Zero learning curve – connect Google Analytics in two minutes.  
- Choose exactly which metrics you want.  
- Receive them on your schedule (daily at 8am, or weekly on Monday).  
- All delivered via clean, mobile‑friendly email.

**Why This Works Without Stripe:**  
Google Analytics OAuth is supported globally. Firebase Auth already provides Google sign‑in, so users can authenticate and authorize your app to read their GA data in one flow. No payment processor needed until you monetize.

---

## Architecture

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | Flutter | Single codebase for web, iOS, Android |
| **Web Hosting** | Vercel | Serves static Flutter web build with global CDN |
| **Backend** | Firebase Functions (Python) | API endpoints, GA OAuth callback, scheduled report generation |
| **Database** | Firestore | User profiles, GA connections, report preferences, logs |
| **Authentication** | Firebase Auth | Email/password + Google sign‑in |
| **Google Analytics** | Google Analytics Data API v1 (OAuth) | Read‑only access to user's GA4 data |
| **Email** | Resend | Sends report emails (3,000/month free) |
| **Scheduling** | Firebase Functions (scheduled) | Triggers report generation every hour |

---

## Why This Stack Works Without Stripe

- **Google Analytics OAuth** – Firebase Auth already has Google sign‑in. You can request the GA API scope during authentication. No Stripe account needed.
- **Firebase Functions** – Python support is free and integrates seamlessly with Google Cloud APIs.
- **All free tiers** – GA API has 10,000 free requests per day per project.

---

## Data Model (Firestore Collections)

### `users`
- Document ID = Firebase Auth UID  
- Fields:  
  - `email` (string)  
  - `displayName` (string)  
  - `createdAt` (timestamp)

### `ga_connections`
- Document ID = auto‑generated  
- Fields:  
  - `userId` (reference to users document)  
  - `propertyId` (string) – GA4 property ID (e.g., `123456789`)  
  - `connectedAt` (timestamp)

### `report_preferences`
- Document ID = auto‑generated (or userId)  
- Fields:  
  - `userId` (reference)  
  - `frequency` (string: 'daily' or 'weekly')  
  - `dayOfWeek` (int, 1=Monday, only for weekly)  
  - `timeOfDay` (string, e.g., "08:00")  
  - `metricsEnabled` (map: `{ users: true, sessions: true, pageviews: true, bounce_rate: true, avg_session_duration: true }`)  
  - `emailEnabled` (boolean)  
  - `updatedAt` (timestamp)

### `report_logs`
- Document ID = auto‑generated  
- Fields:  
  - `userId` (reference)  
  - `sentAt` (timestamp)  
  - `metrics` (map: actual values sent)  
  - `status` (string: 'sent', 'failed')  
  - `error` (string, optional)

---

## Google Analytics Metrics

| Metric | API Name | Description |
|--------|----------|-------------|
| **Users** | `activeUsers` | Number of unique users |
| **Sessions** | `sessions` | Total number of sessions |
| **Pageviews** | `screenPageViews` | Total number of page views |
| **Bounce Rate** | `bounceRate` | Percentage of single‑page sessions |
| **Avg. Session Duration** | `averageSessionDuration` | Average length of a session (seconds) |

---

## Firebase Functions (Python) – Endpoints

### 1. HTTP Functions

#### `POST /ga/callback`
- **Purpose:** Handle Google OAuth callback, store GA4 property ID.
- **Input:** OAuth `code` (query param), user's Firebase token (passed as state).
- **Action:** Exchanges code for refresh token, fetches GA4 property list, lets user select one property, saves to Firestore.

#### `POST /preferences` (callable)
- **Purpose:** Save or update a user's report preferences.  
- **Auth:** Firebase Auth token required.  
- **Input:** JSON with frequency, dayOfWeek, timeOfDay, metricsEnabled, emailEnabled.  
- **Action:** Upserts document in `report_preferences`.

#### `GET /preferences` (callable)
- **Purpose:** Fetch current preferences for the authenticated user.

#### `GET /ga/status` (callable)
- **Purpose:** Check if user has connected a Google Analytics property.

### 2. Scheduled Function

#### `send_reports` (scheduled every hour)
- **Query** Firestore for users whose `frequency` and `timeOfDay` match the current hour (and day of week if weekly).  
- **For each user:**
  - Retrieve their GA property ID from `ga_connections` and refresh token.
  - Call Google Analytics Data API to fetch metrics for the previous day.
  - Build an HTML email with only the metrics the user enabled.
  - Send email via Resend.
  - Log result in `report_logs`.

---

## Development Roadmap (7 Days)

### Day 1 – Project Setup & Authentication
- Create Firebase project; enable Firestore, Auth (Email/Password + Google sign‑in).
- Create Flutter project; add dependencies:  
  `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `flutter_web_auth`, `http`.
- Configure Firebase for Flutter (download config files).
- Build sign‑up / sign‑in screens with Google sign‑in.
- After login, create a `users` document with basic profile.

**Deliverable:** Users can sign up/in and see a simple dashboard.

---

### Day 2 – Google Analytics OAuth Integration
- Enable Google Analytics API in Google Cloud Console (under your Firebase project).
- Create OAuth 2.0 credentials (Web client, and for mobile you can use Firebase Auth's built‑in Google sign‑in with scopes).
- Configure redirect URIs for Firebase Functions (e.g., `https://yourproject.cloudfunctions.net/ga/callback`).
- Write Firebase Function `ga_callback` (Python) that exchanges OAuth code for refresh token.
- In Flutter, implement OAuth flow:
  - **Web:** Use Firebase Auth's Google sign‑in with additional scopes: `https://www.googleapis.com/auth/analytics.readonly`
  - **Mobile:** Similar flow using `GoogleSignIn` with scopes.
- After success, fetch the user's GA4 properties and let them select one.
- Store the property ID and refresh token in Firestore (encrypted).

**Deliverable:** Users can connect their Google Analytics account and select a property.

---

### Day 3 – Report Preferences UI & API
- Build a settings screen with:
  - Frequency picker (daily/weekly)
  - Day of week picker (if weekly)
  - Time picker
  - Checklist of metrics (users, sessions, pageviews, bounce rate, avg. session duration)
- Create callable Firebase Functions to save and retrieve preferences.
- Connect UI to call these functions.
- Add option to disconnect GA.

**Deliverable:** Users can set their report preferences and see them saved.

---

### Day 4 – GA Metrics Fetching (Server‑side)
- In Firebase Functions, add a helper module that uses Google Analytics Data API (Python client).
- Implement function to fetch metrics for a given date range:
  - **Users:** `activeUsers`
  - **Sessions:** `sessions`
  - **Pageviews:** `screenPageViews`
  - **Bounce Rate:** `bounceRate` (return as percentage)
  - **Avg. Session Duration:** `averageSessionDuration` (format as mm:ss)
- Use the stored refresh token to obtain an access token for each user.

**Deliverable:** You can manually call a test function to get metrics for a connected GA property.

---

### Day 5 – Report Generation & Email Sending
- Create a scheduled Firebase Function (`send_reports`) that runs every hour.
- The function queries Firestore for users whose `frequency` and `timeOfDay` match the current time.
- For each user, call the metric‑fetching helper (using their stored credentials).
- Build a simple HTML email with only the metrics the user enabled.
- Send email via Resend (store API key in Firebase environment variables).
- Log the result in `report_logs`.

**Deliverable:** Reports are sent automatically on schedule.

---

### Day 6 – Flutter Web Build & Vercel Deployment
- Run `flutter build web` to generate production files.
- Push code to GitHub repository.
- In Vercel, import the repository.
- Configure build settings:
  - **Build Command:** `flutter build web`
  - **Output Directory:** `build/web`
- Add `vercel.json` for client‑side routing:
  ```json
  {
    "routes": [{ "src": "/(.*)", "dest": "/index.html" }]
  }
  ```
- Deploy. The app will be live at `inboxpulse.vercel.app` (or custom domain).

**Deliverable:** Live web app at a public URL.

---

### Day 7 – Testing, Polish & Launch
- End‑to‑end test with real Google Analytics accounts.
- Verify email delivery and formatting.
- Add error handling (e.g., if GA API fails, log and show user a message).
- Polish UI: loading indicators, error messages, responsive design.
- Write simple onboarding flow.
- Launch on Product Hunt, indie hacker communities, and social media.

**Deliverable:** A fully functional MVP ready for early users.

---

## Cost Analysis (Free Tier)

| Service | Free Tier Limits | Estimated Usage for MVP |
|---------|------------------|--------------------------|
| **Firebase** | Firestore: 1 GiB storage, 50K reads/day, 20K writes/day; Functions: 2M invocations/month | Easily covers hundreds of users |
| **Vercel** | 100GB bandwidth, 100hrs build time | Static hosting for Flutter web |
| **Google Analytics API** | 10,000 requests/day per project | Enough for 100 users with 1 report/day each |
| **Resend** | 3,000 emails/month free | Enough for ~100 daily users (1 email/day each) |

**Total monthly cost: $0** (until you exceed free tiers, at which point you likely have paying customers).

---

## Monetization Strategy (Post‑MVP)

Once you have users and validate demand, introduce a paid plan:

- **Free tier:** One GA property, daily reports, 3 metrics max, last 7 days history.
- **Pro tier:** $9/month – multiple properties, all metrics, 90‑day history, custom branding, priority support.

You can use **Paddle** or **Lemon Squeezy** as your payment processor (both support Philippine businesses).

---

## Next Steps

1. **Set up Firebase project** and enable Firestore & Auth.
2. **Enable Google Analytics API** in Google Cloud Console.
3. **Create OAuth credentials** with GA scope.
4. **Build Flutter app** with Google sign‑in + GA scopes.
5. **Write Firebase Functions (Python)** for OAuth callback and report scheduling.
6. **Build the UI** for preferences.
7. **Deploy and launch.**
