# JobSeeker

A mobile **job-search & career app** built with Flutter and Firebase. **Job-seekers** register, browse
and filter real job listings, analyze their CV with AI to get personalized job recommendations, track
the applications they've sent, and discuss in a community forum. **Companies** get a separate experience:
a dedicated onboarding, their own posted jobs, and an applicant pipeline where they accept/reject
applicants — each of whom is notified.

> Every account is a `seeker`, a `company`, or `admin`. Companies and
> seekers are fully separated: companies go through a **minimal company onboarding** (not the seeker
> career questionnaire), see a **company home + "Lowongan Saya"** instead of the seeker hub, **cannot
> apply** to jobs, and **manage applicants** to the jobs they own. See `CHANGE_PLAN_2.0.md` (Parts 1–9)
> and `firebase.md` for the full schema.

## Team Members

| ID | Name |
|----|------|
| 5025231005 | Muiz Surya Fata |
| 5025231009 | Sanie Ghanda Prawira |
| 5025231008 | Alfa Radithya Fanany |

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore |
| Messaging | Firebase Cloud Messaging + `flutter_local_notifications` |
| Monitoring | Firebase Crashlytics + Firebase Analytics |
| State management | `provider` (forum & notifications) + `StreamBuilder`/`FutureBuilder` |
| Navigation | Navigator 1.0 + named routes |
| Backend plan | Firebase **Spark** (no Cloud Functions) |
| iOS bundle id | `com.muizfata.jobseeker` |

**External APIs:** Adzuna (job listings) · Anthropic Claude (CV analysis & recommendations).

---

# Feature Distribution by Member

The app is split into three feature areas. Each section lists the features built, the full **CRUD**
operations (with their Firestore collections and repository methods), the **external APIs**, and the
**cloud services** used.

---

## 👤 Muiz Surya Fata — Authentication, Job Listings & AI CV Analyzer

**Features built**
- Email/password **registration, login, and onboarding** (industry, city, experience level) — shared
  auth foundation used by the whole app. **Role-aware routing** (`AuthGate`): seekers see the career
  questionnaire, **companies see a dedicated company onboarding** (company name, city, industry), keyed
  on a `companyOnboarded` flag so even already-registered companies are onboarded once.
- **Industry picker with custom entry** (`IndustryPicker`): pick a preset industry **or type your own**
  when it isn't listed — used in seeker onboarding, company onboarding, and edit-profile.
- **Editable profile** (seeker: name/phone/bio; **company: name + city + industry** relabeled).
- **Job feed** from Adzuna with infinite scroll, **keyword search**, and filters (location, category,
  contract type), plus a **job detail** page with "Apply" (opens the source posting). Apply/Save are
  **hidden for company accounts**.
- **Saved jobs** with a personal editable note per job.
- **AI CV analysis**: upload a CV file (**PDF/TXT**), text is extracted on-device and sent to Claude,
  which returns editable skill chips + experience level + summary (the raw CV is never stored).
- **AI job recommendations**: Claude compares the CV profile against jobs and returns a match score
  and skill gaps; results feed the home dashboard.

**CRUD operations**

| Entity (Firestore) | Create | Read | Update | Delete |
|---|---|---|---|---|
| **User profile** `users/{uid}` | `signUp` + `createProfile` (role `seeker`/`company`) | `getCurrentProfile` / `watchCurrentProfile` | `completeOnboarding`, `completeCompanyOnboarding`, `updateProfile` (+ optional `city`/`industry`) | `deleteProfile` (+ auth account) |
| **Saved jobs** `users/{uid}/savedJobs/{jobId}` | `toggle` (save) | `watchSavedJobs`, `watchIsSaved` | `updateNote` | `remove` (unsave) |
| **CV profile** `cvProfiles/{uid}` & **recommendations** `recommendations/{uid}` | `saveProfile`, `saveRecommendations` | `getProfile`, `watchProfile`, `getRecommendations` | `saveProfile` (re-save edited skills) | `deleteProfile` (profile + recommendations) |

- Repositories: `auth_repository.dart`, `user_repository.dart`, `saved_job_repository.dart`, `cv_repository.dart`._

**External APIs**
- **Adzuna Jobs API** — `GET /v1/api/jobs/{country}/search/{page}` (feed, search, filter) and
  `/categories` (filter options). Results cached locally to save quota.
- **Anthropic Claude API** — `POST /v1/messages` (model `claude-opus-4-8`) for CV extraction and job
  ranking; CV text extracted client-side via `syncfusion_flutter_pdf` + `file_picker`.

**Cloud services**
- **Firebase Authentication** (email/password).
- **Cloud Firestore**: `users` (+ `savedJobs` subcollection), `cvProfiles`, `recommendations`.

---

## 👤 Sanie Ghanda Prawira — Application Tracker, Company Job Board & Home Dashboard

**Features built**
- **Application tracker**: record applications (name, DOB, address, phone, **platform** such as
  LinkedIn/Email), a **status workflow** (Dikirim → Ditinjau → Interview → Tes → Tawaran Diterima →
  Ditolak) with **status history** and **color-coded** badges, personal notes, a **7-day
  stale-application reminder** (creates an in-app notification, no server needed), duplicate-application
  guard, and swipe-to-delete with undo. **Status-edit rule:** for a **company-posted** job only the
  company changes status (seeker sees it read-only); for **self-tracked external** applications the
  seeker still self-updates.
- **Company job board + ownership**: a `company`-role user posts internal openings, now **stamped with
  `createdBy`**. Management (Edit / Delete / "Lihat Pelamar") is gated on **ownership**, not just role.
  **"Lowongan Saya"** (`my_jobs_screen`) lists a company's own jobs; legacy un-owned jobs can be
  **claimed** ("Klaim Lowongan Ini" → backfills applicants' `jobOwnerId`).
- **Applicant pipeline**: a company sees who applied to its jobs (`watchApplicantsForMyJobs`), changes
  status, and **accepts ("Terima") / rejects ("Tolak")** with an optional message. The applicant is
  **notified** (tailored "Selamat! …" / "Mohon maaf …"), the status is color-coded, and an accepted
  applicant sees a **next-steps card** (company + HR name). Rejection sets status `Ditolak` (the shared
  application doc is never hard-deleted, so it stays in the seeker's tracker).
- **Role-aware home dashboard**: seekers get greeting + application stats + AI recommendations + latest
  Adzuna jobs; **companies get a company variant** (posted-jobs / applicants counts + "Kelola Lowongan"
  CTA) and the seeker-only API fetches are **skipped** to save Adzuna quota.

**CRUD operations**

| Entity (Firestore) | Create | Read | Update | Delete |
|---|---|---|---|---|
| **Applications** `applications` | `createApplication` (+ duplicate guard, notifies company), `restore` (undo) | `watchMyApplications` (seeker), `watchApplicantsForMyJobs` (company), `hasApplied` | `updateForm`, `updateStatus` (seeker self-track), `updateStatusByCompany` (company accept/reject + notify + `decisionNote`), `remindStaleApplications` | `deleteApplication` (seeker-only) |
| **Company jobs** `jobs` | `AddJobScreen` (+ `createdBy`) | `jobs_screen` / `my_jobs_screen` (streams), `jobs_details` | `jobs_edit`, `claimJob` (ownership) | `jobs_details` (owner-only delete) |
| **Home dashboard** | — | role-aware aggregation (seeker stats / recommendations / jobs, or company counts) | — | — |

- Repository: `application_repository.dart`, `features/jobs/` (incl. `my_jobs_screen`,
`job_applicants_screen`), `features/home/`._

**External APIs**
- **Adzuna Jobs API** — reused on the dashboard to show the latest jobs matching the user's profile.

**Cloud services**
- **Cloud Firestore**: `applications`, `jobs`.
- Writes **in-app notification documents** to `users/{uid}/notifications` for the 7-day reminders **and
  the applicant lifecycle** (seeker applies → company notified; company accepts/rejects → seeker
  notified) — all client-side, since Spark has no Cloud Functions.

---

## 👤 Alfa Radithya Fanany — Community Forum, Notification Center & Push Notifications

**Features built**
- **Community forum**: questions feed with **category filter**, **sort** (Newest / Most Answered /
  Trending), search, an **"unanswered" badge**, and **15-per-page infinite scroll**; post questions
  (with anonymous option), reply, **upvote**, and edit/delete your own questions.
- **Notification center**: list notifications newest-first, unread styling + bell **badge**, tap to
  navigate, **mark-as-read / mark-all-read**, and swipe-to-delete.
- **Push & local notifications**: Firebase Cloud Messaging client (token save, foreground/background/
  terminated handlers) plus local notifications for foreground display.
- **Crash & analytics monitoring**: Firebase Crashlytics + Analytics wired at app start.

**CRUD operations**

| Entity (Firestore) | Create | Read | Update | Delete |
|---|---|---|---|---|
| **Questions** `questions/{id}` | `createQuestion` | `getQuestions` | `updateQuestion`, `upvoteQuestion` (transaction) | `deleteQuestion` |
| **Replies** `questions/{id}/replies/{id}` | `addReply` (transaction + atomic `replyCount` increment) | `getReplies` | — (parent `replyCount` maintained) | `deleteReply` (decrement count) |
| **Notifications** `users/{uid}/notifications/{id}` | created on new reply / upvote, 7-day reminders, **and applicant-lifecycle events** (apply / accept / reject) | `getNotifications` (stream) | `markAsRead`, `markAllAsRead` | `deleteNotification` |

- Repositories: `forum_repository.dart`, `notification_repository.dart`; service: `notification_service.dart`._

**External APIs**
- None — forum and notifications are fully Firestore-driven.

**Cloud services**
- **Cloud Firestore**: `questions` (+ `replies` subcollection), `users/{uid}/notifications`.
- **Firebase Cloud Messaging** — device token persisted to `users/{uid}`, with foreground/background/
  terminated message handling and tap-to-route.
- **`flutter_local_notifications`** — foreground notification display + Android importance channel.
- **Firebase Crashlytics + Analytics** — fatal-error and event reporting.

---

## Summary

| Member | Firestore collections | External APIs | Other cloud services |
|---|---|---|---|
| **Muiz Surya Fata** | `users`, `savedJobs`, `cvProfiles`, `recommendations` | Adzuna, Anthropic Claude | Firebase Auth |
| **Sanie Ghanda Prawira** | `applications`, `jobs` (+ writes `notifications`) | Adzuna (dashboard) | — |
| **Alfa Radithya Fanany** | `questions` + `replies`, `notifications` | — | FCM, local notifications, Crashlytics, Analytics |
