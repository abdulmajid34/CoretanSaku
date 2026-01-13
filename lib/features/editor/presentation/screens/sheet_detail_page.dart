import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pastikan import intl
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/paper_background.dart';
import '../../logic/editor_provider.dart';
import '../../data/models/entry_model.dart';
import '../widgets/add_entry_modal.dart';
import '../../../dashboard/logic/dashboard_provider.dart';

class SheetDetailPage extends StatefulWidget {
  final String sheetId;
  final String title;

  const SheetDetailPage(
      {super.key, required this.sheetId, required this.title});

  @override
  State<SheetDetailPage> createState() => _SheetDetailPageState();
}

class _SheetDetailPageState extends State<SheetDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().loadEntriesForSheet(widget.sheetId);
    });
  }

  // DIALOG EDIT JUDUL
  void _showEditTitleDialog(BuildContext context, String currentTitle) {
    final TextEditingController titleController =
        TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3),
        title: Text("Ganti Judul",
            style: GoogleFonts.patrickHand(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: GoogleFonts.patrickHand(fontSize: 18),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.ink)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.ink, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal",
                style: GoogleFonts.patrickHand(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                context
                    .read<DashboardProvider>()
                    .renameSheet(widget.sheetId, titleController.text);
                Navigator.pop(ctx);
              }
            },
            child: Text("Simpan",
                style: GoogleFonts.patrickHand(
                    color: AppColors.ink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // LOGIC KAMERA (Dengan Auto-Retry & Notif yang Benar)
  Future<void> _pickAndScanImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 40);

    if (photo != null) {
      if (!context.mounted) return;

      final editorProvider = context.read<EditorProvider>();

      // Panggil Scan
      final EntryModel? result = await editorProvider.scanAndAddEntry(
          widget.sheetId, File(photo.path));

      if (!context.mounted) return;

      if (result != null) {
        // SUKSES
        context
            .read<DashboardProvider>()
            .updateSheetBalance(widget.sheetId, result.amount, isExpense: true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✨ Sukses! ${result.content} berhasil dicatat."),
            backgroundColor: AppColors.highlightGreen,
          ),
        );
      } else {
        // GAGAL
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Gagal memproses struk (Server Busy). Coba lagi nanti."),
            backgroundColor: AppColors.highlightRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink),
            onPressed: () => Navigator.pop(context),
          ),
          // JUDUL SHEET DINAMIS
          title: Consumer<DashboardProvider>(
            builder: (context, dashboard, child) {
              try {
                final currentSheet =
                    dashboard.sheets.firstWhere((s) => s.id == widget.sheetId);
                return Text(
                  currentSheet.title,
                  style: GoogleFonts.patrickHand(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } catch (e) {
                return Text(widget.title);
              }
            },
          ),
          actions: [
            // TOMBOL MENU (EDIT)
            Consumer<DashboardProvider>(builder: (context, dashboard, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.ink),
                onPressed: () {
                  try {
                    final currentSheet = dashboard.sheets
                        .firstWhere((s) => s.id == widget.sheetId);
                    _showEditTitleDialog(context, currentSheet.title);
                  } catch (e) {}
                },
              );
            }),
          ],
        ),
        body: Column(
          children: [
            // 1. INFO SALDO HEADER
            Consumer<DashboardProvider>(
              builder: (context, dashboard, child) {
                try {
                  final currentSheet = dashboard.sheets
                      .firstWhere((s) => s.id == widget.sheetId);
                  final balance = currentSheet.currentBalance;
                  final isNegative = balance < 0;

                  return Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    color: Colors.white.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Jumlah Sisa Uangmu:",
                          style: GoogleFonts.patrickHand(
                              color: Colors.grey[700], fontSize: 14),
                        ),
                        Text(
                          currencyFormat.format(balance),
                          style: GoogleFonts.patrickHand(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isNegative
                                ? AppColors.highlightRed
                                : AppColors.highlightGreen,
                          ),
                        ),
                        const Divider(color: AppColors.ink, thickness: 1),
                      ],
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              },
            ),

            // 2. LIST CATATAN
            Expanded(
              child: Consumer<EditorProvider>(
                builder: (context, provider, child) {
                  final entries = provider.getEntries(widget.sheetId);

                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        "Masih kosong...\nYuk catat sesuatu!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.patrickHand(
                            fontSize: 20, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    itemCount: entries.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(color: Colors.black12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];

                      return Dismissible(
                        key: Key(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          final amount = entry.amount;
                          final isExpense = entry.type == EntryType.expense;

                          context
                              .read<EditorProvider>()
                              .deleteEntry(widget.sheetId, entry.id);

                          if (entry.type != EntryType.todo) {
                            context.read<DashboardProvider>().revertBalance(
                                widget.sheetId, amount,
                                wasExpense: isExpense);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${entry.content} dihapus")),
                          );
                        },
                        child: _buildEntryItem(context, entry, currencyFormat),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // TOMBOL SCAN
            Consumer<EditorProvider>(
              builder: (context, provider, _) {
                if (provider.isScanning) {
                  return const FloatingActionButton(
                    heroTag: "scan_loading",
                    onPressed: null,
                    backgroundColor: Colors.white,
                    child: CircularProgressIndicator(),
                  );
                }
                return FloatingActionButton(
                  heroTag: "scan_btn",
                  backgroundColor: AppColors.highlightGreen,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => _pickAndScanImage(context),
                );
              },
            ),
            const SizedBox(height: 16),
            // TOMBOL MANUAL
            FloatingActionButton.extended(
              heroTag: "manual_btn",
              backgroundColor: AppColors.ink,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Text("Catat",
                  style: GoogleFonts.patrickHand(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddEntryModal(sheetId: widget.sheetId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET ITEM (Updated: Dengan Tanggal)
  Widget _buildEntryItem(
      BuildContext context, EntryModel entry, NumberFormat fmt) {
    bool hasItems = entry.items.isNotEmpty;
    bool hasNote = entry.note != null && entry.note!.isNotEmpty;

    // FORMAT TANGGAL OTOMATIS (Menggunakan dd/MM/yyyy HH:mm)
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateString = dateFormat.format(entry.createdAt);

    // FORMAT HARGA
    String priceText = fmt.format(entry.amount);
    Color priceColor = AppColors.ink;

    if (entry.type == EntryType.income) {
      priceText = "+$priceText";
      priceColor = AppColors.highlightGreen;
    } else if (entry.type == EntryType.expense) {
      priceText = "-$priceText";
      priceColor = AppColors.highlightRed;
    }

    // TAMPILAN KHUSUS BELANJA (TODO) - Tanpa Tanggal
    if (entry.type == EntryType.todo) {
      return ListTile(
        leading: Checkbox(
          value: entry.isChecked,
          activeColor: AppColors.ink,
          onChanged: (val) {
            context
                .read<EditorProvider>()
                .toggleCheck(widget.sheetId, entry.id);
          },
        ),
        title: Text(
          entry.content,
          style: GoogleFonts.patrickHand(
              fontSize: 18,
              decoration: entry.isChecked ? TextDecoration.lineThrough : null),
        ),
        subtitle: hasNote
            ? Text(entry.note!,
                style: GoogleFonts.patrickHand(color: Colors.grey))
            : null,
      );
    }

    // TAMPILAN PENGELUARAN/PEMASUKAN - Dengan Tanggal
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Icon(
            entry.type == EntryType.income
                ? Icons.arrow_circle_down
                : Icons.receipt_long,
            color: entry.type == EntryType.income
                ? AppColors.highlightGreen
                : AppColors.ink),
        title: Text(
          entry.content,
          style: GoogleFonts.patrickHand(
              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        // --- SUBTITLE TANGGAL ---
        subtitle: Text(
          dateString,
          style: GoogleFonts.patrickHand(fontSize: 12, color: Colors.grey),
        ),
        // ------------------------
        trailing: Text(
          priceText,
          style: GoogleFonts.patrickHand(
              fontSize: 16, fontWeight: FontWeight.bold, color: priceColor),
        ),

        children: [
          if (hasNote)
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 16, bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Text(
                  "📝 ${entry.note}",
                  style: GoogleFonts.patrickHand(
                      fontSize: 14, color: AppColors.ink),
                ),
              ),
            ),
          if (hasItems)
            ...entry.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 50, right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text("${item.qty}x ${item.name}",
                            style: GoogleFonts.patrickHand(
                                fontSize: 14, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis)),
                    Text(fmt.format(item.price * item.qty),
                        style: GoogleFonts.patrickHand(
                            fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              );
            }).toList()
          else if (!hasNote)
            Padding(
              padding: const EdgeInsets.only(left: 50, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Catatan manual",
                    style: GoogleFonts.patrickHand(
                        color: Colors.grey, fontSize: 12)),
              ),
            )
        ],
      ),
    );
  }
}
