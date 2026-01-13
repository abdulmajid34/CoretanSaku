import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/editor/data/models/entry_model.dart';

class AiService {
  late final GenerativeModel _model;

  AiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception("API Key tidak ditemukan di .env!");

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  Future<EntryModel?> scanReceipt(String sheetId, File imageFile) async {
    int attempt = 0;
    const maxRetries = 3; // Coba maksimal 3 kali

    while (attempt < maxRetries) {
      try {
        final imageBytes = await imageFile.readAsBytes();

        final prompt = TextPart("""
          Analisa gambar struk belanja ini.
          Ekstrak informasi ke format JSON (Strict):
          1. "merchant": Nama Toko.
          2. "total": Total bayar (Number/Double).
          3. "items": Array [{ "name": "Nama Barang", "price": 1000, "qty": 1 }].
          
          Format JSON Wajib:
          {
            "merchant": "Indomaret",
            "total": 50000,
            "items": [
              { "name": "Roti", "price": 10000, "qty": 1 }
            ]
          }
          Hanya return raw JSON string. Tanpa markdown.
        """);

        final imagePart = DataPart('image/jpeg', imageBytes);

        final response = await _model.generateContent([
          Content.multi([prompt, imagePart])
        ]);

        final responseText = response.text;
        if (responseText == null) return null;

        final cleanJson =
            responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);

        List<ItemDetail> parsedItems = [];
        if (data['items'] != null) {
          for (var item in data['items']) {
            parsedItems.add(ItemDetail(
              name: item['name'] ?? 'Item',
              price: (item['price'] as num).toDouble(),
              qty: item['qty'] ?? 1,
            ));
          }
        }

        return EntryModel.create(
          sheetId: sheetId,
          type: EntryType.expense,
          content: data['merchant'] ?? 'Struk Belanja',
          amount: (data['total'] as num).toDouble(),
          items: parsedItems,
          note: "Hasil Scan Struk",
        );
      } catch (e) {
        // Cek jika errornya karena Server Overloaded (503)
        if (e.toString().contains('503') ||
            e.toString().contains('Overloaded')) {
          attempt++;
          print("⚠️ Server sibuk, mencoba lagi... (Percobaan ke-$attempt)");
          await Future.delayed(
              const Duration(seconds: 2)); // Tunggu 2 detik sebelum coba lagi
        } else {
          // Jika error lain (misal gambar buram), langsung stop
          print("Error Gemini Fatal: $e");
          return null;
        }
      }
    }

    print("❌ Gagal scan setelah $maxRetries percobaan.");
    return null;
  }
}
