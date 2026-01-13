import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
// Tambahkan import PaperBackground
import '../../../../core/widgets/paper_background.dart';
import '../../../dashboard/logic/dashboard_provider.dart';
import '../../../dashboard/presentation/screens/dashboard_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final provider = context.read<DashboardProvider>();
    await provider.loadInitialData();

    if (provider.hasUser && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardPage(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // GUNAKAN PAPER BACKGROUND AGAR SERAGAM
    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Agar tekstur kertas terlihat
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // --- LOGO BARU ---
                  // Menggunakan gambar dari assets
                  Image.asset(
                    'assets/images/CoretanSakuHD.png',
                    height: 200, // Atur ukuran sesuai kebutuhan
                  ),

                  const SizedBox(height: 30),

                  // JUDUL SAMBUTAN (Warna Teks Diubah ke AppColors.ink)
                  Text(
                    "Halo, Penulis!",
                    style: GoogleFonts.patrickHand(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink, // Warna tinta gelap
                    ),
                  ),
                  Text(
                    "Siapkan kopi, mari catat cerita keuanganmu.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.patrickHand(
                      fontSize: 20,
                      // Warna tinta gelap dengan sedikit transparansi
                      color: AppColors.ink.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // INPUT FIELD
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.8), // Sedikit transparan
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.ink,
                          width: 1.5), // Tambah border biar tegas
                    ),
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.patrickHand(
                          fontSize: 24, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: "Siapa namamu?",
                        hintStyle:
                            GoogleFonts.patrickHand(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL MULAI
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          await context
                              .read<DashboardProvider>()
                              .setUsername(name);
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const DashboardPage()),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Isi nama dulu dong, biar akrab! 😄",
                                style: GoogleFonts.patrickHand(
                                    color: Colors.white),
                              ),
                              backgroundColor: AppColors.ink,
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Mulai Menulis 📝",
                        style: GoogleFonts.patrickHand(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    "Versi 1.0 • Coretan Saku | Developer by SpaceEgg 2026",
                    style: GoogleFonts.patrickHand(
                        color: AppColors.ink
                            .withOpacity(0.6) // Warna teks footer disesuaikan
                        ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
