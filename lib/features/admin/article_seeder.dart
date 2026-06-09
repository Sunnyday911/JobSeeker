import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobseeker/features/repositories/article_repository.dart';

/// One-time demo data: writes a handful of published career articles so the
/// feed (US04/US05) is populated without manual entry. Triggered from a dev
/// button in Profile.
class ArticleSeeder {
  static final _samples = <Map<String, dynamic>>[
    {
      'title': 'Menyusun CV ATS-Friendly yang Lolos Screening',
      'category': 'Resume Tips',
      'experienceLevel': 'Fresh Graduate',
      'isFeatured': true,
      'bannerUrl':
          'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=800',
      'youtubeVideoId': 'Tt08KmFfIYQ',
      'content':
          'Applicant Tracking Systems (ATS) menyaring CV sebelum dilihat '
              'rekruter. Gunakan format satu kolom, hindari tabel dan gambar, '
              'serta sisipkan kata kunci dari deskripsi pekerjaan. Cantumkan '
              'pencapaian terukur seperti "meningkatkan penjualan 20%" dan '
              'simpan dalam format PDF kecuali diminta lain. Konsistensi font '
              'dan heading yang jelas membantu sistem membaca dokumenmu.',
    },
    {
      'title': '10 Pertanyaan Interview Behavioral dan Cara Menjawabnya',
      'category': 'Interview Prep',
      'experienceLevel': 'Junior',
      'isFeatured': true,
      'bannerUrl':
          'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=800',
      'youtubeVideoId': '1mHjMNZZvFo',
      'content':
          'Pertanyaan behavioral menggali pengalaman nyata. Gunakan metode '
              'STAR: Situation, Task, Action, Result. Siapkan cerita untuk '
              'konflik tim, kegagalan, kepemimpinan, dan tenggat ketat. '
              'Fokus pada kontribusi pribadi dan hasil yang terukur. Latih '
              'jawaban agar ringkas, jujur, dan relevan dengan posisi.',
    },
    {
      'title': 'Strategi Job Search yang Efektif di 2026',
      'category': 'Job Search Strategy',
      'experienceLevel': 'Mid-level',
      'isFeatured': false,
      'bannerUrl':
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800',
      'youtubeVideoId': '',
      'content':
          'Jangan hanya melamar lewat job portal. Manfaatkan referral, '
              'optimalkan profil LinkedIn dengan kata kunci industri, dan '
              'bangun portofolio publik. Lacak setiap lamaran dalam '
              'spreadsheet, lakukan follow-up sopan setelah seminggu, dan '
              'sesuaikan CV untuk tiap peran. Kualitas lamaran mengalahkan '
              'kuantitas.',
    },
    {
      'title': 'Membangun Personal Branding di LinkedIn',
      'category': 'Networking',
      'experienceLevel': 'Junior',
      'isFeatured': false,
      'bannerUrl':
          'https://images.unsplash.com/photo-1611944212129-29977ae1398c?w=800',
      'youtubeVideoId': 'tQEZErzwsX0',
      'content':
          'Personal branding membuatmu mudah ditemukan rekruter. Tulis '
              'headline yang menjelaskan nilai, bukan sekadar jabatan. '
              'Bagikan insight industri secara konsisten, berkomentar pada '
              'postingan relevan, dan minta rekomendasi dari rekan. '
              'Foto profil profesional dan ringkasan yang menonjolkan dampak '
              'akan meningkatkan kredibilitasmu.',
    },
    {
      'title': 'Negosiasi Gaji untuk Profesional Senior',
      'category': 'Career Development',
      'experienceLevel': 'Senior',
      'isFeatured': false,
      'bannerUrl':
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800',
      'youtubeVideoId': '',
      'content':
          'Riset rentang gaji pasar sebelum negosiasi. Tunjukkan dampak '
              'bisnis yang pernah kamu hasilkan dengan angka konkret. Jangan '
              'menyebut angka pertama bila bisa dihindari, dan pertimbangkan '
              'total kompensasi: bonus, ekuitas, dan fleksibilitas. Tetap '
              'profesional dan tenang; diam setelah menyebut angka adalah '
              'alat yang kuat.',
    },
    {
      'title': 'Transisi Karir ke Bidang Teknologi',
      'category': 'Career Development',
      'experienceLevel': 'Mid-level',
      'isFeatured': false,
      'bannerUrl':
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
      'youtubeVideoId': 'zOjov-2OZ0E',
      'content':
          'Pindah ke tech tidak selalu butuh gelar baru. Identifikasi '
              'transferable skills, bangun proyek nyata, dan ikuti bootcamp '
              'atau kursus bersertifikat. Kontribusi open source dan '
              'portofolio GitHub memperkuat lamaran. Jaring koneksi di '
              'komunitas teknologi dan mulai dari peran hybrid yang '
              'memanfaatkan pengalaman lamamu.',
    },
  ];

  /// Writes the samples directly (computing read time like the repo does).
  static Future<void> seed() async {
    final col = FirebaseFirestore.instance.collection('articles');
    for (final s in _samples) {
      await col.add({
        ...s,
        'authorName': 'CareerCompass Editorial',
        'isPublished': true,
        'readTimeMinutes':
            ArticleRepository.estimateReadTime(s['content'] as String),
        'viewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
