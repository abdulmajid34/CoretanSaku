import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/paper_background.dart';
import '../../logic/dashboard_provider.dart';
import '../../data/models/sheet_model.dart';
import '../../../editor/presentation/screens/sheet_detail_page.dart';
// Import Landing Page untuk navigasi saat Logout
import '../../../onboarding/presentation/screens/landing_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load data saat aplikasi dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadInitialData();
    });
  }

  // DIALOG BUAT LEMBARAN BARU
  void _showCreateSheetDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDF6E3), // Warna kertas
        title: Text("Judul Lembaran Baru",
            style: GoogleFonts.patrickHand(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: GoogleFonts.patrickHand(fontSize: 18),
          decoration: InputDecoration(
            hintText: "Misal: Liburan Bali, Tabungan Nikah...",
            hintStyle: GoogleFonts.patrickHand(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.ink)),
            focusedBorder: const UnderlineInputBorder(
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
                    .addSheet(titleController.text, 0);
                Navigator.pop(ctx);
              }
            },
            child: Text("Buat",
                style: GoogleFonts.patrickHand(
                    color: AppColors.ink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return PaperBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // HEADER JUDUL
            Text(
              "Jurnal Keuangan",
              style: GoogleFonts.patrickHand(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),

            // SUB-HEADER (NAMA USER + TOMBOL LOGOUT)
            Consumer<DashboardProvider>(
              builder: (context, provider, _) {
                final year = DateTime.now().year;
                return Row(
                  children: [
                    Text(
                      "${provider.username}'s Diary $year",
                      style: GoogleFonts.patrickHand(
                        fontSize: 18,
                        color: AppColors.ink.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // TOMBOL KECIL UNTUK GANTI NAMA (LOGOUT)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        // Dialog Konfirmasi
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFFFDF6E3),
                            title: Text("Ganti Nama?",
                                style: GoogleFonts.patrickHand(
                                    fontWeight: FontWeight.bold)),
                            content: Text(
                                "Kamu akan kembali ke halaman depan untuk mengisi nama baru.",
                                style: GoogleFonts.patrickHand()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text("Batal",
                                    style: GoogleFonts.patrickHand(
                                        color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text("Ya, Ganti",
                                    style: GoogleFonts.patrickHand(
                                        color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          // 1. Reset Username
                          await provider.logout();

                          // 2. Kembali ke Landing Page
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LandingPage()),
                            (route) => false,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.edit_square,
                            size: 16, color: AppColors.ink.withOpacity(0.5)),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // LIST DATA SHEET
            Expanded(
              child: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  if (provider.sheets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Belum ada catatan...\nMulai tulis ceritamu!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.patrickHand(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildAddButton(context),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.sheets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.sheets.length) {
                        return _buildAddButton(context);
                      }

                      final sheet = provider.sheets[index];
                      final visualNumber = index + 1;

                      return Dismissible(
                        key: Key(sheet.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.white, size: 32),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFFFDF6E3),
                              title: Text("Hapus Lembaran?",
                                  style: GoogleFonts.patrickHand(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24)),
                              content: Text(
                                  "Semua catatan di dalam lembaran ini akan hilang selamanya.",
                                  style: GoogleFonts.patrickHand(fontSize: 18)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text("Batal",
                                        style: GoogleFonts.patrickHand(
                                            color: Colors.grey, fontSize: 18))),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text("Hapus",
                                        style: GoogleFonts.patrickHand(
                                            color: Colors.red, fontSize: 18))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          context
                              .read<DashboardProvider>()
                              .deleteSheet(sheet.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Lembaran telah dibuang ke tempat sampah")),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            String titleToSend = sheet.title;
                            if (!titleToSend.contains("#")) {
                              titleToSend = "$titleToSend #$visualNumber";
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SheetDetailPage(
                                  sheetId: sheet.id,
                                  title: titleToSend,
                                ),
                              ),
                            );
                          },
                          child: _buildSheetItem(
                            context,
                            sheet,
                            visualNumber,
                            currencyFormat.format(sheet.currentBalance),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showCreateSheetDialog(context),
        child: Container(
          margin: const EdgeInsets.only(top: 20, bottom: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.5),
          ),
          child: Text(
            "+ Tambah Kertas Baru",
            style: GoogleFonts.patrickHand(
                fontSize: 18,
                color: AppColors.ink,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetItem(
      BuildContext context, SheetModel sheet, int number, String balance) {
    final isNegative = balance.contains('-');

    String displayTitle = sheet.title;
    if (!displayTitle.contains("#")) {
      displayTitle = "$displayTitle #$number";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sheet.isPinned
            ? const Color(0xFFFFF8E1)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(20),
          bottomLeft: const Radius.circular(25),
          bottomRight: const Radius.circular(5),
        ),
        border: Border.all(
          color: sheet.isPinned ? Colors.orange : AppColors.ink,
          width: sheet.isPinned ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(4, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: GoogleFonts.patrickHand(
                      fontSize: 20, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Sisa: $balance",
                  style: GoogleFonts.patrickHand(
                      fontSize: 16,
                      color: isNegative
                          ? Colors.red
                          : (sheet.isPinned
                              ? Colors.orange[800]
                              : Colors.grey)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<DashboardProvider>().togglePin(sheet.id);
            },
            icon: Icon(
              sheet.isPinned ? Icons.star : Icons.star_border,
              color: sheet.isPinned ? Colors.orange : Colors.grey,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
