# InboxPulse – Automated Stripe Reports Delivered to Your Inbox

## Product Overview

**InboxPulse** is a simple SaaS that connects to your Stripe account and emails you the key metrics you care about – daily or weekly. No dashboards, no logins, just numbers in your inbox.

**Target Audience:** SaaS founders, freelancers, small business owners who want to track revenue, MRR, new customers, and churn without manual work.

**Unique Value:**  
- Zero learning curve – connect Stripe in two minutes.  
- Choose exactly which metrics you want.  
- Receive them on your schedule (daily at 8am, or weekly on Monday).  
- All delivered via clean, mobile‑friendly email.

---

## Architecture

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | Flutter | Single codebase for web, iOS, Android |
| **Web Hosting** | Vercel | Serves static Flutter web build with global CDN |
| **Backend** | Firebase Functions (Python) | API endpoints, Stripe OAuth callback, scheduled report generation |
| **Database** | Firestore | User profiles, Stripe connections, report preferences, logs |
| **Authentication** | Firebase Auth | Email/password + Google sign‑in |
| **Stripe** | Stripe Connect (OAuth) | Read‑only access to user's Stripe data |
| **Email** | Resend | Sends report emails (3,000/month free) |
| **Scheduling** | Firebase Functions (scheduled) | Triggers report generation every hour |

---

## Why This Stack?

- **Flutter** – one codebase for all platforms; great UI consistency.  
- **Firebase** – free tier includes Auth, Firestore, and Functions (Python support).  
- **Vercel** – free static hosting with automatic deployments from GitHub.  
- **Resend** – generous free email tier (3,000 emails/month).  
- **Stripe Connect** – free for read‑only access (no transaction fees).

All components offer generous free tiers, making the MVP **$0/month** to run.

---

## Data Model (Firestore Collections)

### `users`
- Document ID = Firebase Auth UID  
- Fields:  
  - `email` (string)  
  - `displayName` (string)  
  - `createdAt` (timestamp)

### `stripe_accounts`
- Document ID = auto‑generated  
- Fields:  
  - `userId` (reference to users document)  
  - `stripeUserId` (string) – Stripe account ID (e.g., `acct_...`)  
  - `connectedAt` (timestamp)

### `report_preferences`
- Document ID = auto‑generated (or userId)  
- Fields:  
  - `userId` (reference)  
  - `frequency` (string: 'daily' or 'weekly')  
  - `dayOfWeek` (int, 1=Monday, only for weekly)  
  - `timeOfDay` (string, e.g., "08:00")  
  - `metricsEnabled` (map: `{ revenue: true, mrr: true, new_customers: true, churned_customers: true, aov: true }`)  
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

## Firebase Functions (Python) – Endpoints

### 1. HTTP Functions

#### `POST /stripe/callback`
- **Purpose:** Exchange OAuth `code` for `stripe_user_id` and save it to Firestore.  
- **Input:** `code` (query param), `uid` (Firebase Auth UID, passed as state parameter).  
- **Output:** Redirect to app with success/failure message.

#### `POST /preferences` (callable)
- **Purpose:** Save or update a user's report preferences.  
- **Auth:** Firebase Auth token required.  
- **Input:** JSON with frequency, dayOfWeek, timeOfDay, metricsEnabled, emailEnabled.  
- **Action:** Upserts document in `report_preferences`.

#### `GET /preferences` (callable)
- **Purpose:** Fetch current preferences for the authenticated user.

#### `GET /stripe/status` (callable)
- **Purpose:** Check if user has connected a Stripe account.

### 2. Scheduled Function

#### `send_reports` (scheduled every hour)
- **Query** Firestore for users whose `frequency` and `timeOfDay` match the current hour (and day of week if weekly).  
- **For each user:**
  - Retrieve their `stripeUserId` from `stripe_accounts`.
  - Call Stripe API to fetch metrics for the previous day (or week for weekly).
  - Build an HTML email with only the metrics the user enabled.
  - Send email via Resend.
  - Log result in `report_logs`.

---

## Development Roadmap (7 Days)

### Day 1 – Project Setup & Authentication
- Create Firebase project; enable Firestore, Auth (Email/Password + Google).
- Create Flutter project; add dependencies:  
  `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_web_auth`, `http`.
- Configure Firebase for Flutter (download config files).
- Build sign‑up / sign‑in screens.
- After login, create a `users` document with basic profile.

**Deliverable:** Users can sign up/in and see a simple dashboard.

---

### Day 2 – Stripe OAuth Integration
- Set up Stripe Connect platform in test mode; get `client_id`.
- Write Firebase Function `stripe_callback` (Python) that exchanges `code` for `stripeUserId` and saves it under the authenticated user.
- In Flutter, implement OAuth flow:
  - **Web:** `window.location.href` redirect to Stripe's OAuth URL with `client_id`, `scope=read_only`, and `redirect_uri`. Pass user's Firebase token as `state`.
  - **Mobile:** `flutter_web_auth` to open in‑app browser, then capture redirect.
- After success, call a Function to confirm connection.
- Update UI to show connected status.

**Deliverable:** Users can connect their Stripe account via OAuth.

---

### Day 3 – Report Preferences UI & API
- Build a settings screen with:
  - Frequency picker (daily/weekly)
  - Day of week picker (if weekly)
  - Time picker
  - Checklist of metrics (revenue, MRR, new customers, churn, AOV)
- Create callable Firebase Functions to save and retrieve preferences.
- Connect UI to call these functions.
- Add option to disconnect Stripe.

**Deliverable:** Users can set their report preferences and see them saved.

---

### Day 4 – Stripe Metrics Fetching (Server‑side)
- In Firebase Functions, add a helper module that uses Stripe Python library.
- Implement functions to compute:
  - **Daily revenue:** PaymentIntents created yesterday.
  - **MRR:** Sum of active subscription amounts.
  - **New customers:** Customers created yesterday.
  - **Churned customers:** Subscriptions canceled yesterday.
  - **Average order value:** Revenue / number of successful payments yesterday.
- Write unit tests (optional) to verify with test Stripe data.

**Deliverable:** You can manually call a test function to get metrics for a connected Stripe account.

---

### Day 5 – Report Generation & Email Sending
- Create a scheduled Firebase Function (`send_reports`) that runs every hour.
- The function queries Firestore for users whose `frequency` and `timeOfDay` match the current time.
- For each user, call the metric‑fetching helper (using their `stripeUserId`).
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
- End‑to‑end test with real Stripe test accounts.
- Verify email delivery and formatting.
- Add error handling (e.g., if Stripe API fails, log and show user a message).
- Polish UI: loading indicators, error messages, responsive design.
- Write simple onboarding flow (tutorial or tooltips).
- Launch on Product Hunt, indie hacker communities, and social media.

**Deliverable:** A fully functional MVP ready for early users.

---

## Cost Analysis (Free Tier)

| Service | Free Tier Limits | Estimated Usage for MVP |
|---------|------------------|--------------------------|
| **Firebase** | Firestore: 1 GiB storage, 50K reads/day, 20K writes/day; Functions: 2M invocations/month | Easily covers hundreds of users |
| **Vercel** | 100GB bandwidth, 100hrs build time | Static hosting for Flutter web |
| **Stripe** | Free for read‑only API access | No cost |
| **Resend** | 3,000 emails/month free | Enough for ~100 daily users (1 email/day each) |

**Total monthly cost: $0** (until you exceed free tiers, at which point you likely have paying customers).

---

## Monetization Strategy (Post‑MVP)

Once you have users and validate demand, introduce a paid plan:

- **Free tier:** One data source (Stripe), daily reports, 3 metrics max, last 7 days history.
- **Pro tier:** $9/month – unlimited data sources (future), all metrics, 90‑day history, custom branding, priority support.

You can also offer a 14‑day free trial of Pro features to convert free users.

---

## Next Steps

1. **Set up Firebase project** and enable Firestore & Auth.
2. **Create Flutter project** and configure Firebase.
3. **Write Firebase Functions (Python)** for OAuth and report scheduling.
4. **Build the Flutter UI** for authentication, Stripe connection, preferences.
5. **Deploy Functions** using Firebase CLI.
6. **Build and deploy Flutter web** to Vercel.
7. **Test thoroughly** and launch.

 