import 'package:shared_preferences/shared_preferences.dart';
import '../../features/dashboard/data/models/sheet_model.dart';
import '../../features/editor/data/models/entry_model.dart';

class LocalStorageService {
  static const String _keySheets = 'sheets_data';
  static const String _keyEntriesPrefix = 'entries_';

  // --- SHEET OPERATIONS ---

  Future<void> saveSheets(List<SheetModel> sheets) async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List<Object> jadi List<String JSON>
    final List<String> jsonList = sheets.map((s) => s.toJson()).toList();
    await prefs.setStringList(_keySheets, jsonList);
  }

  Future<List<SheetModel>> loadSheets() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_keySheets);

    if (jsonList == null) return [];

    return jsonList.map((str) => SheetModel.fromJson(str)).toList();
  }

  // --- ENTRY OPERATIONS ---

  // Kita simpan entries per Sheet ID agar tidak menumpuk di satu key besar
  Future<void> saveEntries(String sheetId, List<EntryModel> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setStringList('$_keyEntriesPrefix$sheetId', jsonList);
  }

  Future<List<EntryModel>> loadEntries(String sheetId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList =
        prefs.getStringList('$_keyEntriesPrefix$sheetId');

    if (jsonList == null) return [];

    return jsonList.map((str) => EntryModel.fromJson(str)).toList();
  }
}
