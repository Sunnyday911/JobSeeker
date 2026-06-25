import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jobseeker/features/services/adzuna_service.dart'; // Pastikan path import ini sesuai

class EditJobScreen extends StatefulWidget {
  final String jobId; // ID unik dokumen di Firestore
  final Map<String, dynamic> jobData; // Data pekerjaan saat ini

  const EditJobScreen({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  // Controller untuk mengisi dan mengambil teks dari TextField
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  // Variabel untuk Dropdown Kategori
  List<({String tag, String label})> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi otomatis form dengan data yang sudah ada
    _titleController = TextEditingController(text: widget.jobData['title'] ?? '');
    _companyController = TextEditingController(text: widget.jobData['company'] ?? '');
    _locationController = TextEditingController(text: widget.jobData['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.jobData['description'] ?? '');

    // Set kategori awal dari data yang ada
    _selectedCategory = widget.jobData['category'];

    // Ambil data kategori dari Adzuna
    _loadCategories();
  }

  // Fungsi untuk mengambil kategori dari AdzunaService
  Future<void> _loadCategories() async {
    try {
      final cats = await AdzunaService.instance.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = cats;

          // SAFETY CHECK: Pastikan kategori lama ada di dalam daftar dropdown Adzuna.
          // Jika tidak ada (misal karena dulu diketik manual), atur ke null agar tidak error.
          bool categoryExists = cats.any((c) => c.tag == _selectedCategory);
          if (!categoryExists) {
            _selectedCategory = null;
          }

          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat kategori dari Adzuna: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengupdate data ke Firestore
  Future<void> _updateJob() async {
    // Validasi form kosong
    if (_titleController.text.trim().isEmpty ||
        _companyController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedCategory == null) { // Tambahan validasi kategori
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom harus diisi!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update dokumen spesifik berdasarkan jobId
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory, // Gunakan variabel dropdown
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lowongan berhasil diperbarui!')),
        );
        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job Info'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Software Engineer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Company Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                hintText: 'e.g. Tech Corp',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. Jakarta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // UBAH JADI DROPDOWN
            _isLoadingCategories
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
                : DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Pilih Kategori',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.tag,
                  child: Text(c.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Job Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe the responsibilities and requirements...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Save/Update
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}