# Getting Dilivvafast onto Google Play — the plain-English guide

Written for someone who has never published an app before. Every step says
where to go, what to click, and what to type. Follow them in order — later
steps depend on earlier ones.

If a step fails, stop there and ask rather than skipping ahead. Skipping in the
middle of this list is how apps get rejected.

---

## Before you start — what you need

| Thing | Why | Cost |
|---|---|---|
| A Google account | To sign in to Play Console | Free |
| Google Play Developer account | Required to publish anything | **$25, one time, forever** |
| Your Firebase project | Already exists (`fast-delivery-d8d5c`) | Free tier is fine |
| Your Paystack dashboard login | To rotate the leaked key | Free |
| About 2 hours | Spread over a day or two | — |

If you do not have the Developer account yet, create it now at
**https://play.google.com/console/signup** — Google sometimes takes up to
48 hours to verify your identity, so start this first and do the rest while
you wait.

### Where do I type the commands?

When this guide says "run this command", it means:

1. Press the **Windows key**, type `Git Bash`, press Enter. A black window opens.
2. Copy the command, then **right-click** inside the black window to paste
   (Ctrl+V often does not work there).
3. Press Enter.

First, get into the project folder. Run this once each time you open a new
window:

```bash
cd "C:/Users/HP/Documents/Codex/2026-05-23/meta-project-dilivvafast-repo-https-github"
```

---

## Step 1 — Create your app's signature

**What this is:** Android will not accept an app unless it is "signed" — think
of it as a wax seal that proves the app came from you. The seal lives in a file
called a *keystore*. You create it once and use it forever.

**Why it matters more than it sounds:** if you lose this file, you can never
update your app again. Not "it is difficult" — you would have to publish a
brand new listing and lose every install and review. Back it up.

### 1a. Create the file

Run this:

```bash
keytool -genkey -v -keystore ~/dilivvafast-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dilivvafast
```

It will ask you questions one at a time:

| It asks | What to type |
|---|---|
| Enter keystore password | Invent a strong password. **Write it down now.** You will not see the characters as you type — that is normal |
| Re-enter new password | The same password |
| What is your first and last name? | Your name |
| Organizational unit / Organization | `Dilivvafast` (or press Enter to skip) |
| City, State, Country code | Your city, state, and `NG` for Nigeria |
| Is CN=... correct? | Type `yes` and press Enter |

When it finishes you have a file at `C:\Users\HP\dilivvafast-upload.jks`.

### 1b. Back it up right now

Copy `dilivvafast-upload.jks` to **two** places that are not this laptop —
Google Drive, a password manager's file vault, an external drive. Save the
password with it, but not in the same plain text file.

Do this before moving on. People skip it and regret it years later.

### 1c. Tell the project where the file is

Run this to create the settings file:

```bash
cat > android/key.properties <<'END'
storePassword=PUT_YOUR_PASSWORD_HERE
keyPassword=PUT_YOUR_PASSWORD_HERE
keyAlias=dilivvafast
storeFile=C:/Users/HP/dilivvafast-upload.jks
END
```

Then open the file and replace both `PUT_YOUR_PASSWORD_HERE` with the real
password:

```bash
notepad android/key.properties
```

Save and close Notepad.

This file is already excluded from Git, so your password will not be uploaded
to GitHub. Do not move it out of the `android` folder.

**Tell me when this is done** — I will build the real, signed app file for you
and confirm the seal is yours and not a test one.

---

## Step 2 — Rotate the Paystack key

**What this is:** a secret password for your payment account was accidentally
published in the code on GitHub. It has been removed from the code, but
removing it is not the same as cancelling it — anyone who copied it can still
use it until you cancel it.

**Do this today.** It is unrelated to the app upload and takes five minutes.

1. Go to **https://dashboard.paystack.com** and log in.
2. Click **Settings** in the left sidebar.
3. Click the **API Keys & Webhooks** tab.
4. Find **Secret Key**. Click **Generate New Secret Key** (or the rotate icon).
5. Confirm. The old key stops working immediately.
6. **Copy the new secret key** and keep it somewhere safe for Step 3.

You will also see a **Public Key** on that page starting with `pk_`. Copy that
too — it is safe to share, and it is used when building the app.

---

## Step 3 — Switch on the backend

**What this is:** the app is only half the product. The other half is code that
runs on Google's servers and does the things the phone is not allowed to do —
taking payments, approving drivers, paying drivers out. That code is written
and tested but has never been switched on.

**Until this is done, the app will install and open, but top-ups, driver
approvals, and cancellations will not work.** That is expected, not a bug.

### 3a. Store your secret keys on the server

Run these one at a time. Each will ask you to paste a value, then press Enter:

```bash
firebase functions:secrets:set PAYSTACK_SECRET_KEY
```

Paste the **new** secret key from Step 2.

```bash
firebase functions:secrets:set PAYSTACK_WEBHOOK_SECRET
```

Paste the same secret key again (Paystack uses it to sign its messages).

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

If you do not have one, type `unused` and press Enter — this only powers the
AI help chat.

### 3b. Check the safety rules still pass

```bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
cd rules_test && npm test && cd ..
```

You want to see **`pass 88`** and **`fail 0`**. If anything fails, stop and
tell me — do not deploy on top of a failing rules test.

### 3c. Publish the rules, then the server code

Order matters here. Run the rules first:

```bash
firebase deploy --only firestore:rules,storage:rules
```

Then the server code:

```bash
firebase deploy --only functions
```

The second one takes several minutes and prints a lot. At the end it lists
your function URLs. **Copy the one ending in `paystackWebhook`** — you need it
in the next step.

Doing these the other way round would briefly leave a gap where the approval
system exists but the rules still let people give themselves admin access.

### 3d. Tell Paystack where to send payment confirmations

1. Back at **https://dashboard.paystack.com** → **Settings** → **API Keys &
   Webhooks**.
2. Find the **Webhook URL** box.
3. Paste the `paystackWebhook` URL you copied.
4. Save.

**Why this matters:** if a customer pays and their phone dies before the app
confirms it, this is what makes sure their wallet still gets credited.

### 3e. Unlock your existing drivers

The app now requires a flag called `isVerifiedDriver` before a driver can go
online. Existing drivers do not have it yet, so **every one of them is
currently locked out**. The script to fix this is in `SECURITY.md` under the
backfill section — tell me when you reach this point and I will walk you
through running it.

---

## Step 4 — Create test accounts for Google's reviewers

**What this is:** a real person at Google opens your app and tries it. Every
screen in Dilivvafast is behind a login, so without accounts they see a login
wall, cannot test anything, and reject the app. This is one of the most common
reasons first submissions fail.

You need two accounts, created through the app itself or Firebase Console:

**Account 1 — a customer**
- Email: something like `reviewer.customer@dilivvafast.ng`
- Give it a wallet balance so payment screens can be explored without a real card

**Account 2 — a driver who is already approved**
- Email: something like `reviewer.driver@dilivvafast.ng`
- In **Firebase Console → Firestore Database → users → (that account)**, set
  `isVerifiedDriver` to `true` and `role` to `driver`

The driver one is essential. A reviewer cannot approve themselves, and an
unapproved driver cannot go online — so without this the whole driver half of
your app looks broken.

Write both email addresses and passwords down. You will paste them into Play
Console in Step 6.

---

## Step 5 — I build the app file

Once Step 1 is done, tell me and I will run the build and check the signature
is genuinely yours. You will get a file called **`app-release.aab`**.

An `.aab` is what Google Play accepts. It is not something you can install
directly on a phone — that is normal.

---

## Step 6 — Set up your Play Console listing

Go to **https://play.google.com/console** and sign in.

### 6a. Create the app

1. Click **Create app** (top right).
2. **App name:** `Dilivvafast`
3. **Default language:** English (United States) or English (United Kingdom)
4. **App or game:** App
5. **Free or paid:** Free
6. Tick the declarations, click **Create app**.

### 6b. Work through the left sidebar

Play Console shows a checklist. Work top to bottom. The ones that need real
thought:

**App access** — choose *All functionality is restricted*. Add the two logins
from Step 4. In the notes box write something like:

> Dilivvafast has three roles. The customer account can book and track a
> delivery. The driver account is pre-approved and can go online and accept
> jobs — driver approval is granted server-side by an administrator, so a new
> account cannot self-approve. Admin tools are internal and not included.

**Ads** — No.

**Content rating** — fill in the questionnaire. Answer honestly:
- Violence, sex, drugs, gambling → No to all
- **Users can communicate with each other** → **Yes** (there is order chat)
- **Users can share their location** → **Yes**
- **Digital purchases** → **Yes** (wallet top-up)

**Target audience** — 18 and over. This avoids extra rules that apply to apps
for children, which you do not want for a payments app.

**Data safety** — the longest form. Every answer is already worked out for you
in **`PLAY_STORE.md`**, section 3. Copy them across. Two things to remember:
- Tick **Data is encrypted in transit** — yes, it is
- Tick **Users can request that data is deleted** — yes, the app has
  Settings → Delete Account

**Privacy policy** — you must give a public web address. See Step 6c.

**Sensitive app permissions → Background location** — you will be asked to
justify it. Say something like:

> Drivers broadcast their location while a delivery is active so the customer
> can track the courier on a live map. Tracking runs only while the driver is
> online with an accepted delivery, and stops when they go offline.

You must also record a **short screen video** showing the disclosure screen
appearing and then the Android permission prompt. Just record your phone
screen while tapping "Go online" as the driver, upload it to Google Drive or
YouTube as unlisted, and paste the link.

I have built that disclosure screen into the app already, so it will appear
when you tap "Go online".

### 6c. Publish your privacy policy

You already have the text in the project at `docs/privacy.html`, but it is not
online yet. The free way to publish it:

1. Go to your repository: **https://github.com/Hubert24hrs/Dilivvafast**
2. Click **Settings** (top of the repo, not your account settings).
3. Click **Pages** in the left sidebar.
4. Under **Source**, choose branch `main` and folder `/docs`, click **Save**.
5. Wait a couple of minutes. Your policy will be live at
   `https://hubert24hrs.github.io/Dilivvafast/privacy.html`
6. Paste that address into Play Console's privacy policy box.

### 6d. Store listing text and pictures

| What | Rules |
|---|---|
| Short description | Max 80 characters |
| Full description | Max 4000 characters |
| App icon | 512×512 pixels, PNG |
| Feature graphic | 1024×500 pixels |
| Screenshots | At least 2, taken on a real phone |

Draft text is in `PLAY_STORE.md`. For screenshots, install the test app on your
phone and capture: the booking screen, the live tracking map, the driver home
screen, and the wallet.

Do not write "fastest" or "cheapest" or "number 1" — Google pulls listings for
claims you cannot prove.

---

## Step 7 — Upload, test, then go live

### 7a. Internal testing first — not production

In Play Console's left sidebar: **Testing → Internal testing → Create new
release**.

1. Upload the `app-release.aab` file.
2. Under **Testers**, create a list and add your own email plus anyone helping.
3. Click **Review release**, then **Start rollout to Internal testing**.

Internal testing skips the full review queue and is usually live in minutes.
You get a link to install the real app from the Play Store on your own phone.

**This is the point of the whole exercise.** If something is broken — the app
crashes on open, payments fail, the map is blank — you find out here, privately,
instead of in a public rejection.

### 7b. Test it properly

Follow the checklist in `TESTING.md`. At minimum, on a real phone:

- Sign up as a new customer, book a delivery
- Log in as your test driver, go online, accept it, complete it
- Top up a wallet with a Paystack **test card**
- Confirm the tracking map shows the driver moving

### 7c. Then production

When internal testing is clean: **Production → Create new release**, upload the
same file, fill in the release notes, roll out.

First reviews typically take a few days but can take up to a week. Google may
come back with questions — usually about background location, which is why the
disclosure screen and the video matter.

---

## The short version

| Step | Who | Time |
|---|---|---|
| 1. Create and back up the keystore | You | 15 min |
| 2. Rotate the Paystack key | You | 5 min |
| 3. Deploy the backend | You | 30 min |
| 4. Create reviewer test accounts | You | 15 min |
| 5. Build the signed app file | Me | — |
| 6. Fill in Play Console | You | 1 hour |
| 7. Internal test, then publish | You | 1 day + review |

**Start with Step 1 and Step 2.** They unblock everything else and neither
depends on anything.
