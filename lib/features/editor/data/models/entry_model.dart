import 'dart:convert';

enum EntryType { expense, income, todo, note }

// CLASS BARU: Untuk menyimpan detail per item barang
class ItemDetail {
  final String name;
  final double price;
  final int qty;

  ItemDetail({required this.name, required this.price, this.qty = 1});

  Map<String, dynamic> toMap() => {'name': name, 'price': price, 'qty': qty};

  factory ItemDetail.fromMap(Map<String, dynamic> map) {
    return ItemDetail(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      qty: map['qty'] ?? 1,
    );
  }
}

class EntryModel {
  final String id;
  final String sheetId;
  final EntryType type;
  final String content; // Nama Toko (misal: Indomaret)
  final double amount; // Total Belanja
  final bool isChecked;
  final String? stickerUrl;
  final String? receiptPath;
  final DateTime createdAt;
  final String? note;

  // FIELD BARU: List barang belanjaan
  final List<ItemDetail> items;

  const EntryModel({
    required this.id,
    required this.sheetId,
    required this.type,
    required this.content,
    this.amount = 0,
    this.isChecked = false,
    this.stickerUrl,
    this.receiptPath,
    required this.createdAt,
    this.items = const [], // Default kosong
    this.note,
  });

  factory EntryModel.create({
    required String sheetId,
    required EntryType type,
    String content = '',
    double amount = 0,
    List<ItemDetail> items = const [],
    String? note,
  }) {
    return EntryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sheetId: sheetId,
      type: type,
      content: content,
      amount: amount,
      createdAt: DateTime.now(),
      items: items,
      note: note,
    );
  }

  EntryModel copyWith({
    String? content,
    double? amount,
    bool? isChecked,
    String? stickerUrl,
    String? receiptPath,
    List<ItemDetail>? items,
    String? note,
  }) {
    return EntryModel(
      id: id,
      sheetId: sheetId,
      type: type,
      content: content ?? this.content,
      amount: amount ?? this.amount,
      isChecked: isChecked ?? this.isChecked,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt,
      items: items ?? this.items,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sheetId': sheetId,
      'type': type.index,
      'content': content,
      'amount': amount,
      'isChecked': isChecked,
      'stickerUrl': stickerUrl,
      'receiptPath': receiptPath,
      'createdAt': createdAt.toIso8601String(),
      // Serialisasi List Item
      'items': items.map((x) => x.toMap()).toList(),
      'note': note,
    };
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'],
      sheetId: map['sheetId'],
      type: EntryType.values[map['type']],
      content: map['content'],
      amount: map['amount'] ?? 0.0,
      isChecked: map['isChecked'] ?? false,
      stickerUrl: map['stickerUrl'],
      receiptPath: map['receiptPath'],
      createdAt: DateTime.parse(map['createdAt']),
      note: map['note'],
      // Deserialisasi List Item (Handle null safety)
      items: map['items'] == null
          ? []
          : List<ItemDetail>.from(
              map['items']?.map((x) => ItemDetail.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());
  factory EntryModel.fromJson(String source) =>
      EntryModel.fromMap(json.decode(source));
}
