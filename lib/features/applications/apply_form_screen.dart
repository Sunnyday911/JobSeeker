import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:jobseeker/features/models/application.dart';
import 'package:jobseeker/features/models/job.dart';
import 'package:jobseeker/features/repositories/application_repository.dart';

/// Apply form (US12 create) — also reused in edit mode (US13). Combined schema:
/// applicant bio + job reference. Pass [job] to create, or [existing] to edit.
class ApplyFormScreen extends StatefulWidget {
  final Job? job;
  final Application? existing;

  const ApplyFormScreen({super.key, this.job, this.existing});

  @override
  State<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends State<ApplyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ApplicationRepository();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _dob; // yyyy-MM-dd
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.fullName;
      _addressCtrl.text = e.address;
      _phoneCtrl.text = e.phone;
      _notesCtrl.text = e.notes;
      _dob = e.dateOfBirth.isEmpty ? null : e.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _jobTitle => widget.existing?.jobTitle ?? widget.job?.title ?? '-';
  String get _company => widget.existing?.company ?? widget.job?.company ?? '-';

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await _repo.updateForm(
          widget.existing!.id,
          fullName: _nameCtrl.text.trim(),
          dateOfBirth: _dob!,
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        final now = DateTime.now();
        await _repo.createApplication(Application(
          id: '',
          userId: FirebaseAuth.instance.currentUser!.uid,
          jobId: widget.job?.id,
          jobTitle: _jobTitle,
          company: _company,
          fullName: _nameCtrl.text.trim(),
          dateOfBirth: _dob!,
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          status: 'Dikirim',
          statusHistory: [StatusChange(status: 'Dikirim', at: now)],
          appliedAt: now,
          updatedAt: now,
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEdit ? 'Lamaran diperbarui.' : 'Lamaran dicatat.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Lamaran' : 'Catat Lamaran')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(_jobTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_company),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nama Lengkap', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir', border: OutlineInputBorder()),
                child: Text(_dob ?? 'Pilih tanggal'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                  labelText: 'Alamat', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'No. Telepon', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Kirim Lamaran'),
            ),
          ],
        ),
      ),
    );
  }
}
