import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/entry_model.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/ai_service.dart';

class EditorProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final AiService _aiService = AiService();

  // Cache data entry per sheet
  Map<String, List<EntryModel>> _entriesBySheet = {};

  // Status Loading saat Scan
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // 1. GET ENTRIES (Ambil data)
  List<EntryModel> getEntries(String sheetId) {
    return _entriesBySheet[sheetId] ?? [];
  }

  // 2. LOAD ENTRIES (Load dari Database HP)
  Future<void> loadEntriesForSheet(String sheetId) async {
    final entries = await _storage.loadEntries(sheetId);
    // Sort: Paling baru di atas
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _entriesBySheet[sheetId] = entries;
    notifyListeners();
  }

  // 3. ADD ENTRY (Manual)
  void addEntry({
    required String sheetId,
    required String content,
    required double amount,
    required EntryType type,
    String? note,
  }) {
    final newEntry = EntryModel.create(
      sheetId: sheetId,
      type: type,
      content: content,
      amount: amount,
      note: note,
    );

    final entries = _entriesBySheet[sheetId] ?? [];
    entries.insert(0, newEntry); // Masukkan ke urutan pertama (Top)
    _entriesBySheet[sheetId] = entries;

    _storage.saveEntries(sheetId, entries);
    notifyListeners(); // Refresh UI
  }

  // UBAH RETURN TYPE JADI Future<EntryModel?>
  Future<EntryModel?> scanAndAddEntry(String sheetId, File imageFile) async {
    _isScanning = true;
    notifyListeners();

    try {
      final newEntry = await _aiService.scanReceipt(sheetId, imageFile);

      if (newEntry != null) {
        final entries = _entriesBySheet[sheetId] ?? [];
        entries.insert(0, newEntry);
        _entriesBySheet[sheetId] = entries;

        await _storage.saveEntries(sheetId, entries);
        // BERHASIL
        return newEntry;
      } else {
        // GAGAL (Return null)
        return null;
      }
    } catch (e) {
      print("Error Provider: $e");
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // 5. DELETE ENTRY
  void deleteEntry(String sheetId, String entryId) {
    final entries = _entriesBySheet[sheetId];
    if (entries == null) return;

    entries.removeWhere((e) => e.id == entryId);
    _entriesBySheet[sheetId] = entries;

    _storage.saveEntries(sheetId, entries);
    notifyListeners();
  }

  // 6. TOGGLE CHECKLIST (Todo)
  void toggleCheck(String sheetId, String entryId) {
    final entries = _entriesBySheet[sheetId];
    if (entries == null) return;

    final index = entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      final old = entries[index];
      entries[index] = old.copyWith(isChecked: !old.isChecked);
      _storage.saveEntries(sheetId, entries);
      notifyListeners();
    }
  }
}
