import 'dart:convert';

class SheetModel {
  final String id;
  final String title;
  final double budgetLimit;
  final double currentBalance;
  final DateTime createdAt;
  final int colorIndex;
  final bool isPinned; // <-- FIELD BARU

  SheetModel({
    required this.id,
    required this.title,
    this.budgetLimit = 0,
    this.currentBalance = 0,
    required this.createdAt,
    this.colorIndex = 0,
    this.isPinned = false, // Default false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'budgetLimit': budgetLimit,
      'currentBalance': currentBalance,
      'createdAt': createdAt.toIso8601String(),
      'colorIndex': colorIndex,
      'isPinned': isPinned, // <-- Simpan ke DB
    };
  }

  factory SheetModel.fromMap(Map<String, dynamic> map) {
    return SheetModel(
      id: map['id'],
      title: map['title'],
      budgetLimit: map['budgetLimit'] ?? 0.0,
      currentBalance: map['currentBalance'] ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
      colorIndex: map['colorIndex'] ?? 0,
      isPinned: map['isPinned'] ??
          false, // <-- Baca dari DB (Handle null untuk data lama)
    );
  }

  String toJson() => json.encode(toMap());
  factory SheetModel.fromJson(String source) =>
      SheetModel.fromMap(json.decode(source));
}
