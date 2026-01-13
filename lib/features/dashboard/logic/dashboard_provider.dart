import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import ini wajib
import '../data/models/sheet_model.dart';
import '../../../core/services/local_storage_service.dart';

class DashboardProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  // STATE SHEET
  List<SheetModel> _sheets = [];
  List<SheetModel> get sheets => _sheets;

  // STATE USERNAME (BARU)
  String _username = "User";
  String get username => _username;

  // Cek apakah user sudah pernah login (nama bukan default & tidak kosong)
  bool get hasUser => _username != "User" && _username.isNotEmpty;

  // --- LOAD DATA AWAL ---
  Future<void> loadInitialData() async {
    // 1. Load Data Sheet
    _sheets = await _storage.loadSheets();
    _sortSheets();

    // 2. Load Username dari Memori HP (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('user_name') ?? "User";

    notifyListeners();
  }

  // --- FITUR USERNAME (BARU) ---
  Future<void> setUsername(String name) async {
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name); // Simpan permanen
    notifyListeners();
  }

  // --- FITUR SHEET ---

  // 1. ADD SHEET
  void addSheet(String title, double initialBalance) {
    final newSheet = SheetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      currentBalance: initialBalance,
      createdAt: DateTime.now(),
      colorIndex: (_sheets.length % 3),
      isPinned: false,
    );

    _sheets.add(newSheet);
    _sortSheets();
    _saveToStorage();
    notifyListeners();
  }

  // 2. DELETE SHEET
  void deleteSheet(String id) {
    _sheets.removeWhere((s) => s.id == id);
    _saveToStorage();
    notifyListeners();
  }

  // 3. TOGGLE PIN
  void togglePin(String id) {
    final index = _sheets.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = _sheets[index];

      _sheets[index] = SheetModel(
        id: old.id,
        title: old.title,
        budgetLimit: old.budgetLimit,
        currentBalance: old.currentBalance,
        createdAt: old.createdAt,
        colorIndex: old.colorIndex,
        isPinned: !old.isPinned, // Flip status
      );

      _sortSheets();
      _saveToStorage();
      notifyListeners();
    }
  }

  // 4. RENAME SHEET
  void renameSheet(String id, String newTitle) {
    final index = _sheets.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = _sheets[index];

      _sheets[index] = SheetModel(
        id: old.id,
        title: newTitle, // Update Judul
        budgetLimit: old.budgetLimit,
        currentBalance: old.currentBalance,
        createdAt: old.createdAt,
        colorIndex: old.colorIndex,
        isPinned: old.isPinned,
      );

      _saveToStorage();
      notifyListeners();
    }
  }

  // 5. UPDATE SALDO
  void updateSheetBalance(String sheetId, double amount,
      {required bool isExpense}) {
    final index = _sheets.indexWhere((s) => s.id == sheetId);

    if (index != -1) {
      final oldSheet = _sheets[index];

      double newBalance;
      if (isExpense) {
        newBalance = oldSheet.currentBalance - amount;
      } else {
        newBalance = oldSheet.currentBalance + amount;
      }

      _sheets[index] = SheetModel(
        id: oldSheet.id,
        title: oldSheet.title,
        createdAt: oldSheet.createdAt,
        colorIndex: oldSheet.colorIndex,
        currentBalance: newBalance,
        budgetLimit: oldSheet.budgetLimit,
        isPinned: oldSheet.isPinned, // Pertahankan status pin
      );

      _sortSheets();
      _saveToStorage();
      notifyListeners();
    }
  }

  // 6. REVERT BALANCE (Refund saat delete entry)
  void revertBalance(String sheetId, double amount,
      {required bool wasExpense}) {
    updateSheetBalance(sheetId, amount, isExpense: !wasExpense);
  }

  // --- PRIVATE HELPERS ---

  void _sortSheets() {
    _sheets.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // FUNGSI BARU: Logout / Reset Nama
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name'); // Hapus key user_name
    _username = "User";
    notifyListeners();
  }

  void _saveToStorage() {
    _storage.saveSheets(_sheets);
  }
}
