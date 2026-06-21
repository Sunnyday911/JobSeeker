# 📘 CareerCompass — Knowledge Transfer Documentation

> Job Listing & Career Guidance App · Flutter (Android) · Firebase **Spark Plan**
> Dokumen ini merangkum status implementasi aktual per member, CRUD, API, cloud service, dan integrasi antar-fitur.
> Penjelasan dalam Bahasa Indonesia; istilah teknis (Dart/Flutter/Firebase) dalam Bahasa Inggris.

## Informasi Project
| Item | Nilai |
|---|---|
| Nama Aplikasi | CareerCompass |
| Platform | Flutter (Android) · Dart |
| State Management | Provider (`ChangeNotifier`) — dipakai di Forum & Notifications; fitur lain memakai `StreamBuilder`/`FutureBuilder` langsung |
| Navigasi | ⚠️ **Navigator 1.0 + named routes** (`MaterialApp.routes` di [main.dart](lib/main.dart)). Brief menyebut `go_router`, tetapi **`go_router` TIDAK dipakai** di implementasi aktual. |
| Backend | Firebase **Spark Plan** |
| Constraint Spark | Firebase Storage tidak dipakai untuk upload — **semua gambar via URL eksternal** (NewsAPI image URL, `article.bannerUrl`). Dependency `firebase_storage` ada di `pubspec.yaml` namun tidak digunakan untuk upload. **Cloud Functions tidak tersedia di Spark** (butuh Blaze) → push notification server-side tidak bisa. |
| API Keys | Hardcoded di [lib/core/api_keys.dart](lib/core/api_keys.dart) (Adzuna + Anthropic). ⚠️ Untuk produksi sebaiknya via `--dart-define` / proxy. |

---

# ════════════════════════════════════════════
# SECTION: MEMBER 1 — Job Listings + AI CV Analyzer + Articles & Guides
# ════════════════════════════════════════════

Branch: `feature/m1-jobs-articles` · Juga memimpin setup **Firebase Auth** (shared).

## 1. CHECKLIST USER STORY

| No | Judul | Status | Keterangan |
|----|-------|--------|-----------|
| US01 | Registrasi dan Login Pengguna | ✅ Selesai | Email/password via FirebaseAuth; validasi password **min 8** + regex email ([validators.dart](lib/core/validators.dart)); pesan error spesifik |
| US02 | Login dengan Google | ❌ Belum dimulai | Package `google_sign_in` **tidak ada** di pubspec; hanya email/password |
| US03 | Onboarding Profil Karir | ✅ Selesai | Pilih industri + **kota domisili** + level pengalaman → simpan ke `users/{uid}` |
| US04 | Menelusuri Lowongan Kerja | ✅ Selesai | Feed real-time dari Adzuna API + infinite scroll + loading + empty state |
| US05 | Mencari dan Memfilter Lowongan | ✅ Selesai | Keyword + filter **lokasi** + **kategori** (dropdown dari Adzuna `fetchCategories`) + tipe kontrak; auto-update saat filter berubah. ⚠️ lokasi pakai indeks Adzuna `gb` (kota Indonesia minim hasil) |
| US06 | Melihat Detail Lowongan Kerja | ✅ Selesai | Judul/perusahaan/lokasi/gaji/tanggal/deskripsi + "Lamar Sekarang" (url_launcher) + "Simpan Lowongan" |
| US07 | Menyimpan Lowongan Favorit | ✅ Selesai | Toggle bookmark → `users/{uid}/savedJobs`; halaman Tersimpan + swipe-to-delete |
| US08 | Analisis CV dengan AI | ✅ Selesai | Paste CV (validasi ≥100 char) → Claude API → skill chips editable → simpan ke `cvProfiles/{uid}` |
| US09 | Rekomendasi Lowongan Berbasis AI | ✅ Selesai | Claude membandingkan CV vs lowongan Adzuna → match score + skill gap, sorted desc, refresh, simpan ke `recommendations/{uid}` |
| US10 | Menelusuri Artikel Panduan Karir | ✅ Selesai | Feed + filter kategori + badge **"Unggulan"** + estimasi waktu baca + berita NewsAPI + admin CRUD |
| US11 | Membaca dan Menyimpan Artikel | ✅ Selesai | Detail artikel + bookmark ke `users/{uid}/bookmarks` + halaman Bookmark + swipe delete |

## 2. CRUD OPERATION YANG DIIMPLEMENTASIKAN

**AUTH (shared)** — [auth_repository.dart](lib/features/repositories/auth_repository.dart), [user_repository.dart](lib/features/repositories/user_repository.dart)
- CREATE : `signUp()` buat akun FirebaseAuth + `createProfile()` → dokumen `users/{uid}` (email, role, fullName, industry/city/experienceLevel=null, onboardingCompleted=false)
- READ : `getCurrentProfile()` / `watchCurrentProfile()` → baca `users/{uid}`; `AuthGate` baca authState
- UPDATE : `completeOnboarding()` (industry, city, experienceLevel, onboardingCompleted=true); `updateProfile()` (fullName, phone, bio)
- DELETE : `deleteProfile()` → hapus dokumen `users/{uid}` + `auth.currentUser.delete()`

**JOB LISTINGS (Adzuna)** — [adzuna_service.dart](lib/features/services/adzuna_service.dart), [saved_job_repository.dart](lib/features/repositories/saved_job_repository.dart)
- CREATE : `SavedJobRepository.toggle()` → simpan lowongan favorit ke `users/{uid}/savedJobs/{jobId}`
- READ : `AdzunaService.searchJobs()` (REST, bukan Firestore) → feed; `watchSavedJobs()` → daftar tersimpan
- UPDATE : ❌ Belum diimplementasikan — data lowongan immutable (sumber Adzuna), tidak ada field yang diupdate
- DELETE : `SavedJobRepository.remove()` / `toggle()` → hapus `users/{uid}/savedJobs/{jobId}` (swipe)

**AI CV ANALYZER (Claude)** — [claude_service.dart](lib/features/services/claude_service.dart), [cv_repository.dart](lib/features/repositories/cv_repository.dart)
- CREATE : `saveProfile()` → `cvProfiles/{uid}` (skills, experienceLevel, summary — **bukan teks CV mentah**); `saveRecommendations()` → `recommendations/{uid}`
- READ : `analyzeCv()` & `rankJobs()` (Claude `/v1/messages`); `getProfile()` baca `cvProfiles/{uid}`
- UPDATE : `saveProfile()` dipakai ulang (skill chips diedit user lalu disimpan) — overwrite dokumen
- DELETE : ❌ Belum diimplementasikan — belum ada aksi hapus profil CV (low priority)

**ARTICLES** — [article_repository.dart](lib/features/repositories/article_repository.dart), [bookmark_repository.dart](lib/features/repositories/bookmark_repository.dart)
- CREATE : `ArticleRepository.create()` → `articles/{id}` (admin); `BookmarkRepository.toggle()` → `users/{uid}/bookmarks/{articleId}`
- READ : `watchPublished()` (featured-first, filter kategori/level); `getById()`, `getRelated()`; `NewsService.fetchHeadlines()` (NewsAPI)
- UPDATE : `ArticleRepository.update()` (admin edit artikel); `incrementViewCount()`
- DELETE : `ArticleRepository.delete()` (admin); `BookmarkRepository.remove()` (hapus bookmark)

## 3. API YANG DIGUNAKAN

| API | Endpoint | Untuk US | Status | Catatan |
|-----|----------|----------|--------|---------|
| Adzuna API | `/v1/api/jobs/{country}/search/{page}` | US04, US05, US09 | ✅ Terintegrasi | country=`gb` (Adzuna tak punya indeks Indonesia); cache 30 menit; key di api_keys.dart |
| Adzuna API | `/v1/api/jobs/{country}/categories` | US05 | ✅ Terintegrasi | `fetchCategories()` → dropdown filter kategori di UI |
| Claude / Anthropic | `POST /v1/messages` | US08, US09 | ✅ Terintegrasi | Model `claude-opus-4-8`; structured output `output_config.format`; key terverifikasi live |
| NewsAPI | `/v2/top-headlines` | US10 | ✅ Terintegrasi | Cache in-memory 1 jam; key hardcoded di [news_service.dart](lib/features/services/news_service.dart) |

## 4. CLOUD SERVICE YANG DIGUNAKAN

| Service | Koleksi/Fitur | Digunakan untuk | Status | Catatan |
|---------|---------------|-----------------|--------|---------|
| Firebase Auth | email/password | US01, US03 | ✅ | Google Sign-In ❌ (US02) |
| Cloud Firestore | `users/{uid}` | US01, US03 | ✅ | + subkoleksi `savedJobs`, `bookmarks` |
| Cloud Firestore | `cvProfiles/{uid}`, `recommendations/{uid}` | US08, US09 | ✅ | ⚠️ brief menyebut `cvAnalysis/{userId}` — nama aktual `cvProfiles` |
| Cloud Firestore | `articles/{id}` | US10, US11 | ✅ | Admin CRUD via [manage_articles_screen.dart](lib/features/admin/manage_articles_screen.dart) |
| Firebase Storage | — | — | ❌ Tidak dipakai | Spark constraint — gambar via URL eksternal |

## 5. INTEGRASI ANTAR FITUR
- **Kirim ke member lain:** profil `users/{uid}` (industry/city/level) dipakai Dashboard M2 (sapaan, seed lowongan) & filter level Artikel; lowongan Adzuna (`Job`) → Application Tracker M2 (tombol "Catat Lamaran" di job detail).
- **Terima dari member lain:** Dashboard M2 menampilkan rekomendasi + lowongan + artikel milik M1.
- **Cross-navigation:** Job detail → ApplyForm (M2) & SavedJobs; Recommendations → "Pelajari di Artikel" (kategori Career Development); Profil → Analisis CV/Rekomendasi, Lowongan Tersimpan.
- **Onboarding → Jobs:** feed Adzuna otomatis di-seed dari `industry` user.

## 6. KNOWN ISSUES & CATATAN TEKNIS
- **US02 Google login** ❌ — perlu tambah `google_sign_in` + konfigurasi OAuth Firebase.
- **US05** ✅ — filter lokasi (`where`) + kategori (`category`, dropdown via `fetchCategories`) + kontrak sudah di UI dan auto-reload. ⚠️ country Adzuna=`gb` → query kota Indonesia minim hasil (keterbatasan data Adzuna, bukan bug); sumber Indonesia memakai jobs "Perusahaan".
- **Adzuna country** = `gb`; ubah `_country` di [adzuna_service.dart](lib/features/services/adzuna_service.dart) bila ingin pasar lain (`sg`/`in` lebih dekat regional).
- **Claude API key** terekspos di binary (hardcoded) — risiko produksi; idealnya proxy via Cloud Function (butuh Blaze).
- **Nama koleksi** beda dari brief: `cvProfiles` (bukan `cvAnalysis`), `users/{uid}/savedJobs` (bukan `savedJobs/{userId}/jobs`), `users/{uid}/bookmarks` (bukan `bookmarks/{userId}/articles`).

---

# ════════════════════════════════════════════
# SECTION: MEMBER 2 — Application Tracker + Salary Insights + Home Dashboard
# ════════════════════════════════════════════

Branch: `feature/m2-salary-tracker`

## 1. CHECKLIST USER STORY

| No | Judul | Status | Keterangan |
|----|-------|--------|-----------|
| US12 | Melamar Pekerjaan | ✅ Selesai | Form lamaran (nama, tgl lahir, alamat, telepon + job ref) → `applications`; cegah duplikat per job |
| US13 | Melacak dan Memperbarui Status Lamaran | ✅ Selesai | Dropdown status (Dikirim…Ditolak) + riwayat status + catatan; ⚠️ reminder 7 hari ❌ (butuh Cloud Functions) |
| US14 | Menghapus Lamaran | ✅ Selesai | Swipe + dialog konfirmasi + Snackbar "Batalkan" (undo) |
| US15 | Menelusuri Data Gaji | ❌ Belum diimplementasikan | **Tidak ada kode** — Adzuna salary histogram/history belum diintegrasi, tak ada koleksi `salaries` |
| US16 | Mengirim dan Mengelola Data Gaji | ❌ Belum diimplementasikan | **Tidak ada kode** — fitur Salary Insights belum dibuat sama sekali |
| US17 | Dashboard Beranda | ✅ Selesai | Hub agregat: sapaan, stats lamaran, CTA rekomendasi/CV, lowongan terbaru, artikel unggulan, badge notifikasi. ⚠️ section "data gaji" tidak ada (US15/16 belum dibuat) |

## 2. CRUD OPERATION YANG DIIMPLEMENTASIKAN

**APPLICATION TRACKER** — [application_repository.dart](lib/features/repositories/application_repository.dart)
- CREATE : `createApplication()` → koleksi top-level `applications` (field `userId`); cek `hasApplied(jobId)` untuk cegah duplikat (US12.5); `restore()` untuk undo
- READ : `watchMyApplications()` → `where('userId'==uid)` lalu sort client-side (hindari composite index)
- UPDATE : `updateForm()` (edit field lamaran); `updateStatus()` (status + `statusHistory` via `FieldValue.arrayUnion`)
- DELETE : `deleteApplication()` → hapus dokumen (swipe + konfirmasi)

**COMPANY JOBS BOARD** (internal, dipakai sebagai sumber lowongan Indonesia; terhubung ke tracker) — [jobs/](lib/features/jobs/)
- CREATE : `AddJobScreen` → `jobs/{id}` (role `company`); fields title/company/poster_name/salary/location/category/description
- READ : `CompanyJobsView` StreamBuilder atas `jobs` (toggle "Perusahaan" di tab Lowongan)
- UPDATE : `EditJobScreen` → update `jobs/{id}` (owner company)
- DELETE : `CompanyJobDetailScreen` hapus `jobs/{id}` (owner company, dengan konfirmasi)

**SALARY INSIGHTS**
- CREATE/READ/UPDATE/DELETE : ❌ Belum diimplementasikan — seluruh fitur Salary Insights (US15, US16) belum dibangun; koleksi `salaries/{salaryId}` belum ada; endpoint Adzuna salary belum dihubungkan.

**HOME DASHBOARD** (read-only agregat) — [home_dashboard_screen.dart](lib/features/home/home_dashboard_screen.dart)
- READ : stats dari `applications`, profil CV dari `cvProfiles`, lowongan dari Adzuna, artikel dari `articles`, unread count dari `NotificationProvider`
- CREATE/UPDATE/DELETE : ❌ Tidak relevan — dashboard hanya menampilkan/agregasi (navigasi ke fitur sumber)

## 3. API YANG DIGUNAKAN

| API | Endpoint | Untuk US | Status | Catatan |
|-----|----------|----------|--------|---------|
| Adzuna API | `/v1/api/jobs/{country}/search` | US17 | ✅ Terintegrasi | Dashboard "Lowongan terbaru" (reuse service M1) |
| Adzuna API | `/v1/api/jobs/{country}/histogram` | US15 | ❌ Belum diimplementasikan | Endpoint salary histogram belum dihubungkan |
| Adzuna API | `/v1/api/jobs/{country}/history` | US15 | ❌ Belum diimplementasikan | Endpoint salary history belum dihubungkan |

## 4. CLOUD SERVICE YANG DIGUNAKAN

| Service | Koleksi/Fitur | Digunakan untuk | Status | Catatan |
|---------|---------------|-----------------|--------|---------|
| Cloud Firestore | `applications` (top-level + `userId`) | US12, US13, US14 | ✅ | ⚠️ brief menyebut `applications/{userId}/jobs`; aktual top-level |
| Cloud Firestore | `jobs/{id}` | (sumber lowongan internal) | ✅ | Papan lowongan perusahaan (role `company`) |
| Cloud Firestore | `salaries/{salaryId}` | US15, US16 | ❌ Belum diimplementasikan | Koleksi belum dibuat |
| Cloud Firestore | (agregasi lintas koleksi) | US17 | ✅ | Dashboard membaca applications/cvProfiles/articles |

## 5. INTEGRASI ANTAR FITUR
- **Terima dari M1:** objek `Job` (Adzuna) → tombol "Catat Lamaran" membuat lamaran; profil `users/{uid}` → sapaan + seed lowongan dashboard; `cvProfiles`/`recommendations` → CTA dashboard; `articles` → section artikel dashboard.
- **Kirim ke M3:** ❌ Belum — perubahan status lamaran **belum** membuat notifikasi (US13.5 reminder 7 hari butuh Cloud Functions/penjadwal).
- **Cross-navigation:** Dashboard → MyApplications, Recommendations/CV, Job detail, Articles feed; Application detail (status Interview) → Artikel "Interview Prep".

## 6. KNOWN ISSUES & CATATAN TEKNIS
- **Salary Insights (US15, US16)** ❌ — fitur paling besar yang belum ada. Perlu: `SalaryRepository`, layar histogram/history, integrasi Adzuna salary endpoints, koleksi `salaries`.
- **Reminder status 7 hari (US13.5)** ❌ — butuh server scheduler (Cloud Functions = Blaze). Tidak mungkin murni client di Spark.
- **Composite index dihindari**: query lamaran pakai single-field `where` + sort client-side (tak perlu buat index Firestore).
- **Dashboard** sengaja body-only (pakai AppBar `main_screen`); tab lain masih punya AppBar sendiri (double app bar pre-existing — kosmetis).

---

# ════════════════════════════════════════════
# SECTION: MEMBER 3 — Community Forum + Push Notifications
# ════════════════════════════════════════════

Branch: `feature/m3-forum-notif`

## 1. CHECKLIST USER STORY

| No | Judul | Status | Keterangan |
|----|-------|--------|-----------|
| US18 | Menelusuri Pertanyaan Forum | 🔄 Dalam Pengerjaan | Feed + jumlah reply/upvote ✅; **belum**: filter kategori, sort (Terbaru/Trending), badge "Belum Dijawab", pagination 15/halaman (saat ini limit 20) |
| US19 | Memposting Pertanyaan | 🔄 Dalam Pengerjaan | Judul (counter 100) + kategori wajib + opsi anonim + simpan ✅; **belum**: counter 1000 char isi, lampiran YouTube, edit/hapus pertanyaan sendiri |
| US20 | Membalas Pertanyaan dan Upvote | 🔄 Dalam Pengerjaan | Reply ke sub-koleksi + `replyCount` atomik (`FieldValue.increment`) + notif in-app ✅; **belum**: cegah dobel-upvote, upvote pada reply, edit/hapus reply |
| US21 | Menandai Jawaban Terbaik | ❌ Belum dimulai | Tidak ada `isMarkedHelpful`/`isResolved`; tombol "Tandai Jawaban Terbaik" belum ada |
| US22 | Pusat Notifikasi | ✅ Selesai | List urut terbaru, unread di-styling, tap→navigasi, mark-as-read, mark-all, swipe delete, **badge** di lonceng beranda |
| US23 | Notifikasi Push Otomatis | 🔄 Dalam Pengerjaan | FCM client init + simpan token + minta izin + handler foreground/background ✅; **push server-side ❌ (Spark tak punya Cloud Functions)** |

## 2. CRUD OPERATION YANG DIIMPLEMENTASIKAN

**FORUM** — [forum_repository.dart](lib/features/repositories/forum_repository.dart)
- CREATE : `createQuestion()` → `questions/{id}`; `addReply()` → `questions/{id}/replies/{id}` (transaction + `replyCount` increment); membuat notif in-app ke `users/{authorId}/notifications`
- READ : `getQuestions()` (limit 20, terbaru); `getReplies(questionId)` (sub-koleksi)
- UPDATE : `updateQuestion()` & `upvoteQuestion()` (transaction increment upvotes) ada di repo; **edit/upvote dari UI belum lengkap**; `isMarkedHelpful`/`isResolved` ❌
- DELETE : `deleteQuestion()` & `deleteReply()` (decrement `replyCount`) ada di repo; UI hapus milik sendiri belum ada

**PUSH NOTIFICATIONS** — [notification_repository.dart](lib/features/repositories/notification_repository.dart), [notification_service.dart](lib/features/notifications/notification_service.dart)
- CREATE : notif in-app dibuat saat ada reply/like (oleh Forum) → `users/{uid}/notifications/{id}`; `saveTokenToFirestore()` simpan `fcmToken` ke `users/{uid}`
- READ : `getNotifications()` stream → Pusat Notifikasi; `NotificationProvider.unreadCount` → badge
- UPDATE : `markAsRead()`, `markAllAsRead()` → field `read=true`
- DELETE : `deleteNotification()` (swipe)

## 3. API YANG DIGUNAKAN

| API | Endpoint | Untuk US | Status | Catatan |
|-----|----------|----------|--------|---------|
| YouTube Data API v3 | `/youtube/v3/search` | US19 | ❌ Belum diimplementasikan | Auto-attach video tutorial per kategori belum dihubungkan ke provider |

## 4. CLOUD SERVICE YANG DIGUNAKAN

| Service | Koleksi/Fitur | Digunakan untuk | Status | Catatan |
|---------|---------------|-----------------|--------|---------|
| Cloud Firestore | `questions/{id}` + `replies/{id}` | US18, US19, US20 | ✅ | Sub-koleksi replies; `replyCount`/`upvotes` |
| Cloud Firestore | `users/{uid}/notifications/{id}` | US22 | ✅ | ⚠️ brief menyebut `notifications/{notifId}` top-level; aktual per-user subkoleksi |
| Firebase Cloud Messaging (FCM) | token + handler | US23 | 🔄 | Client setup ✅ (token, izin, foreground/background, routing). **Push server-side ❌ — Spark tak bisa Cloud Functions** |
| flutter_local_notifications | tampilan notif foreground | US23 | ✅ | Dipakai menampilkan pesan FCM saat foreground; **reminder lokal terjadwal ❌** |

## 5. INTEGRASI ANTAR FITUR
- **Terima dari member lain:** event reply/upvote (Forum) memicu pembuatan dokumen notifikasi.
- **Kirim ke member lain:** Forum → Notifikasi (dokumen notif). Tap notifikasi forum → route `'forum'` (sudah didaftarkan di [main.dart](lib/main.dart)) → buka feed forum.
- **Cross-navigation:** lonceng (badge) di AppBar beranda → Pusat Notifikasi; tap notif → halaman relevan.
- ❌ **Belum:** notifikasi dari Application Tracker (status) & job-match (butuh trigger server / Cloud Functions).

## 6. KNOWN ISSUES & CATATAN TEKNIS
- **US23 push otomatis** terbatas: **Spark Plan tidak mendukung Cloud Functions**, jadi push yang dipicu server (balasan baru, reminder, job match) tidak bisa dikirim. Yang ada: notif **in-app** (dokumen Firestore) + infrastruktur FCM client untuk **menerima** push.
- **US21 jawaban terbaik** ❌ — tambah field `isMarkedHelpful` (reply) & `isResolved` (question) + tombol khusus pemilik pertanyaan.
- **US18–US20** 🔄 — perlu: query kategori/sort + pagination (`startAfter`), counter 1000 char, integrasi YouTube, cegah dobel-upvote (simpan daftar voter), upvote reply, edit/hapus milik sendiri.
- **YouTube Data API** ❌ — belum ada service/ key.

---

# ════════════════════════════════════════════
# SECTION: RINGKASAN KESELURUHAN
# ════════════════════════════════════════════

## 1. PROGRESS SUMMARY

| Member | Total US | ✅ Selesai | 🔄 Dalam Proses | ❌ Belum | % Selesai (penuh) |
|--------|----------|-----------|------------------|----------|-------------------|
| Member 1 (Jobs/CV/Articles + Auth) | 11 | 10 | 0 | 1 | **91%** |
| Member 2 (Tracker/Salary/Dashboard) | 6 | 4 | 0 | 2 | **67%** |
| Member 3 (Forum/Notifications) | 6 | 1 | 4 | 1 | **17%** |
| **TOTAL PROJECT** | **23** | **15** | **4** | **4** | **≈65%** (penuh) / **≈74%** (tertimbang) |

- ✅ Selesai (15): US01, US03, US04, US05, US06, US07, US08, US09, US10, US11, US12, US13, US14, US17, US22
- 🔄 Proses (4): US18, US19, US20, US23
- ❌ Belum (4): US02, US15, US16, US21

## 2. FITUR YANG BELUM TERINTEGRASI / STANDALONE

| Fitur | Masalah | Saran koneksi (low scope) |
|-------|---------|---------------------------|
| **Salary Insights (M2)** | ❌ Belum dibuat sama sekali | Bangun `SalaryRepository` + layar; tampilkan section gaji di Dashboard & Job detail |
| **Application Tracker → Notifikasi** | Perubahan status tidak menghasilkan notifikasi | Buat dokumen notif in-app saat `updateStatus` (mirip Forum) — tanpa server |
| **Forum** | Hampir island; hanya terhubung ke Notifikasi | (Opsional) link "Diskusikan" dari job/artikel ke Forum |
| **Push server-side (US23)** | Tidak mungkin di Spark | Upgrade ke Blaze + Cloud Functions, atau tetap pakai notif in-app |
| **YouTube di Forum (US19)** | API belum diintegrasi | Tambah `YoutubeService` + simpan `videoId` di dokumen question |

## 3. API SUMMARY TABLE

| Member | API | Status | Endpoint Utama | Free Tier Limit (perkiraan) |
|--------|-----|--------|----------------|------------------------------|
| M1 | Adzuna API | ✅ | `/v1/api/jobs/gb/search/{page}` | ~250 call/hari, 25/menit |
| M1 | Claude / Anthropic | ✅ | `POST /v1/messages` | Pay-as-you-go (bukan free tier) |
| M1 | NewsAPI | ✅ | `/v2/top-headlines` | ~100 req/hari (dev only) |
| M2 | Adzuna salary (histogram/history) | ❌ | `/jobs/gb/histogram`, `/history` | (sama kuota Adzuna) |
| M3 | YouTube Data API v3 | ❌ | `/youtube/v3/search` | ~10.000 unit/hari |

## 4. CLOUD SERVICE SUMMARY

| Service | Digunakan oleh | Koleksi Firestore | Status |
|---------|----------------|-------------------|--------|
| Firebase Auth | M1 (shared) | `users/{uid}` | ✅ (Google ❌) |
| Cloud Firestore | M1, M2, M3 | `users`, `savedJobs`*, `bookmarks`*, `cvProfiles`, `recommendations`, `articles`, `applications`, `jobs`, `questions`+`replies`, `notifications`* | ✅ |
| Firebase Cloud Messaging | M3 | (token di `users/{uid}`) | 🔄 client-only |
| flutter_local_notifications | M3 | — | ✅ (foreground) |
| Firebase Storage | — | — | ❌ (Spark; gambar via URL) |
| Cloud Functions | — | — | ❌ (butuh Blaze) |

\* subkoleksi di bawah `users/{uid}`

## 5. DEPENDENCY MAP (alur data antar-fitur)

```
                         ┌─────────────────────────┐
            Auth/Onboarding  →  users/{uid} profile │
                         └───────────┬─────────────┘
                 industry/city/level │ name
        ┌────────────────────────────┼───────────────────────────┐
        ▼                            ▼                            ▼
  Adzuna Jobs (M1)            HOME DASHBOARD (M2/US17)        Articles (M1)
   search/detail   ───jobs──▶  stats+jobs+recs+articles ◀──featured──┘
        │  save                      ▲        │ tap                   ▲
        ▼                            │        ▼                       │ "Interview Prep"
  savedJobs/{uid}            recommendations  Job detail               │ / "Career Dev"
        │                     (Claude, M1)      │ "Catat Lamaran"      │
        │  CV (Claude, M1)         ▲            ▼                      │
        └──▶ cvProfiles/{uid} ─────┘     Application Tracker (M2) ─────┘
                                          applications/{...}
                                                 │ (status change)
                                                 ✗ belum → Notifikasi

  Forum (M3) ──reply/upvote──▶ users/{uid}/notifications ──▶ Pusat Notifikasi (M3)
   questions/replies                                          + badge lonceng (Dashboard)
        ✗ YouTube belum                                       tap → route 'forum'

  Salary Insights (M2)  ✗ BELUM ADA  (rencana: → Dashboard, → Job detail)
```

## 6. SETUP CHECKLIST UNTUK MEMBER BARU

```
□ Clone repository & checkout branch yang relevan
□ Install Flutter SDK (Dart ^3.11) lalu `flutter pub get`
□ Firebase: pastikan `lib/firebase_options.dart` & `google-services.json` (android/) tersedia
   (project Firebase Spark; aktifkan Auth email/password + Firestore)
□ Isi API keys di lib/core/api_keys.dart (Adzuna app_id/app_key, Anthropic key)
   — produksi: pindahkan ke --dart-define / proxy, JANGAN commit key asli
□ NewsAPI key: cek lib/features/services/news_service.dart
□ Set Firestore Security Rules (per-user akses users/{uid}/**, applications by userId, dst.)
□ Jalankan: `flutter run` (Android)  ·  cek `flutter analyze`
□ Jika menambah Salary Insights / Google login / YouTube: lihat item ❌ di dokumen ini
□ Catatan: navigasi pakai Navigator + named routes (BUKAN go_router); gambar via URL (no Storage)
```

---
*Dokumen ini mencerminkan status kode pada saat penulisan. Setiap item ❌ "Belum diimplementasikan" perlu ditindaklanjuti sesuai catatan di tiap section.*
