// Shared static option lists used across JobSeeker onboarding and filters.

import 'package:flutter/material.dart';

/// Industries shown during onboarding (US03.2).
const List<String> kIndustries = [
  'Technology',
  'Finance',
  'Healthcare',
  'Education',
  'Marketing',
  'Design',
  'Engineering',
  'Human Resources',
  'Sales',
  'Other',
];

/// Experience levels (US03.3, US04.3).
const List<String> kExperienceLevels = [
  'Fresh Graduate',
  'Junior',
  'Mid-level',
  'Senior',
];

/// Indonesian cities for the onboarding domicile picker (US03.3).
const List<String> kIndonesianCities = [
  'Jakarta',
  'Surabaya',
  'Bandung',
  'Medan',
  'Semarang',
  'Makassar',
  'Palembang',
  'Tangerang',
  'Bekasi',
  'Depok',
  'Bogor',
  'Yogyakarta',
  'Malang',
  'Denpasar',
  'Batam',
  'Pekanbaru',
  'Padang',
  'Other',
];

/// Application/lamaran statuses (US13.2).
const List<String> kApplicationStatuses = [
  'Dikirim',
  'Ditinjau',
  'Interview',
  'Tes',
  'Tawaran Diterima',
  'Ditolak',
];

/// Platforms used to send a job application (US12.2).
const List<String> kApplicationPlatforms = [
  'LinkedIn',
  'Email',
  'JobStreet',
  'Glints',
  'Indeed',
  'Website Perusahaan',
  'Lainnya',
];

/// Badge color for an application status (Change Plan 2.0, Part 9): green =
/// accepted, red = rejected, amber = in-progress, grey = default/sent.
Color applicationStatusColor(String status) {
  switch (status) {
    case 'Tawaran Diterima':
      return Colors.green;
    case 'Ditolak':
      return Colors.red;
    case 'Ditinjau':
    case 'Interview':
    case 'Tes':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}
