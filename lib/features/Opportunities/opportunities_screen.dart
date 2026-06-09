import 'package:flutter/material.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({Key? key}) : super(key: key);

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  // Filter yang sedang aktif
  String _selectedType = 'All';

  // Menyimpan daftar tipe lowongan untuk filter chips
  final List<String> _filters = [
    'All',
    'Full-time',
    'Part-time',
    'Internship',
    'Freelance',
    'Volunteer',
    'Contract'
  ];

  // Dummy Data Lowongan (Menyesuaikan spesifikasi dan tren teknologi)
  final List<Map<String, dynamic>> _allListings = [
    {
      'title': 'Data Science & Machine Learning Intern',
      'company': 'Telkom Indonesia',
      'type': 'Internship',
      'location': 'Jakarta (Remote Friendly)',
      'deadline': '25 Jun 2026',
    },
    {
      'title': 'Network Security & Penetration Tester',
      'company': 'CyberSec Nusantara',
      'type': 'Freelance',
      'location': 'Surabaya',
      'deadline': '18 Jun 2026',
    },
    {
      'title': 'Computer Vision Engineer (U-Net Specialist)',
      'company': 'AI Research Lab',
      'type': 'Contract',
      'location': 'Surabaya',
      'deadline': '30 Jun 2026',
    },
    {
      'title': 'Pothole Detection Data Collector',
      'company': 'Smart City Initiative',
      'type': 'Volunteer',
      'location': 'Surabaya (On-site)',
      'deadline': '12 Jun 2026',
    },
    {
      'title': 'Junior Flutter Developer',
      'company': 'Tech Start-up',
      'type': 'Full-time',
      'location': 'Jakarta (Hybrid)',
      'deadline': '05 Jul 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Logika untuk menyaring daftar berdasarkan filter chip yang ditekan
    List<Map<String, dynamic>> filteredListings = _selectedType == 'All'
        ? _allListings
        : _allListings.where((item) => item['type'] == _selectedType).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Jelajah Peluang',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar di bagian atas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Cari posisi atau keahlian...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 2. Horizontal Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedType == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedType = filter;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 3. Vertical Feed List Lowongan
          Expanded(
            child: filteredListings.isEmpty
                ? const Center(
              child: Text('Tidak ada lowongan untuk kategori ini.'),
            )
                : ListView.builder(
              itemCount: filteredListings.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = filteredListings[index];
                return _buildOpportunityCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembuat Kartu Lowongan
  Widget _buildOpportunityCard(Map<String, dynamic> item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mengambil inisial nama perusahaan sebagai logo placeholder
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    item['company']![0],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                // Badge Tipe Lowongan Berwarna Spesifik
                _buildTypeBadge(item['type']),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              item['company'],
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item['location'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Batas: ${item['deadline']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Logika Khusus: Menentukan Warna Badge sesuai Dokumen Spesifikasi
  Widget _buildTypeBadge(String type) {
    Color backgroundColor;
    Color textColor;

    switch (type.toLowerCase()) {
      case 'volunteer':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'internship':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'full-time':
        backgroundColor = const Color(0xFFFFEBE6); // Coral soft background
        textColor = const Color(0xFFFF4500);       // Coral text
        break;
      case 'freelance':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      default:
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}