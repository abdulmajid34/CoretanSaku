import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../logic/editor_provider.dart';
import '../../data/models/entry_model.dart';
import '../../../dashboard/logic/dashboard_provider.dart';

class AddEntryModal extends StatefulWidget {
  final String sheetId;
  const AddEntryModal({super.key, required this.sheetId});

  @override
  State<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends State<AddEntryModal> {
  final _contentController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(); // Controller untuk Catatan

  EntryType _selectedType = EntryType.expense; // Default: Pengeluaran

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF6E3), // Warna Kertas
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PILIHAN TIPE (CHIPS BERWARNA)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTypeChip(
                  "Keluar", EntryType.expense, Colors.red[100]!, Colors.red),
              _buildTypeChip("Masuk", EntryType.income, Colors.green[100]!,
                  Colors.green[800]!),
              _buildTypeChip("Belanja", EntryType.todo, Colors.blue[100]!,
                  Colors.blue[800]!),
            ],
          ),

          const SizedBox(height: 20),

          // 2. INPUT NAMA BARANG
          TextField(
            controller: _contentController,
            style: GoogleFonts.patrickHand(fontSize: 20),
            decoration: InputDecoration(
              hintText: _selectedType == EntryType.income
                  ? "Terima dari..."
                  : "Beli apa tadi?...",
              hintStyle: GoogleFonts.patrickHand(color: Colors.grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          // 3. INPUT HARGA (Hanya muncul jika bukan TODO)
          if (_selectedType != EntryType.todo)
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.patrickHand(
                  fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: "Rp ",
                hintText: "0",
                hintStyle: GoogleFonts.patrickHand(color: Colors.grey),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

          const SizedBox(height: 12),

          // 4. INPUT CATATAN (BARU)
          TextField(
            controller: _noteController,
            style: GoogleFonts.patrickHand(fontSize: 16),
            maxLines: 2, // Bisa 2 baris
            decoration: InputDecoration(
              hintText: "Catatan tambahan (opsional)...",
              hintStyle:
                  GoogleFonts.patrickHand(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white.withOpacity(0.7),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),

          // 5. TOMBOL SUBMIT
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _submitForm,
              child: Text(
                "Tulis di Kertas",
                style: GoogleFonts.patrickHand(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET CHIP CUSTOM (Logic Warna)
  Widget _buildTypeChip(
      String label, EntryType type, Color activeColor, Color activeTextColor) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Logic Warna: Jika selected pakai warna request, jika tidak putih border hitam
          color: isSelected ? activeColor : Colors.white,
          border: Border.all(
              color: isSelected ? activeTextColor : AppColors.ink,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.patrickHand(
            // Warna text mengikuti status
            color: isSelected ? activeTextColor : AppColors.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    final content = _contentController.text;
    if (content.isEmpty) return;

    final amount = double.tryParse(_amountController.text) ?? 0;

    // 1. Simpan ke Editor (List Data)
    context.read<EditorProvider>().addEntry(
          sheetId: widget.sheetId,
          content: content,
          amount: amount,
          type: _selectedType,
          note: _noteController.text, // Kirim Catatan
        );

    // 2. Update Saldo Dashboard
    if (_selectedType != EntryType.todo) {
      context.read<DashboardProvider>().updateSheetBalance(
          widget.sheetId, amount,
          isExpense: _selectedType == EntryType.expense);
    }

    Navigator.pop(context);
  }
}
