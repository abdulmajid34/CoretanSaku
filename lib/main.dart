import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import Screen & Logic
import 'features/dashboard/logic/dashboard_provider.dart';
import 'features/editor/logic/editor_provider.dart';
import 'core/theme/app_colors.dart';

// PENTING: Import Landing Page yang baru dibuat
import 'features/onboarding/presentation/screens/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment Variable (API Key Gemini)
  // Pastikan file .env sudah ada di root project
  await dotenv.load(fileName: ".env");

  runApp(const CoretanSakuApp());
}

class CoretanSakuApp extends StatelessWidget {
  const CoretanSakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
      ],
      child: MaterialApp(
        title: 'Coretan Saku',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Menggunakan warna utama highlightGreen sebagai seed
          colorScheme:
              ColorScheme.fromSeed(seedColor: AppColors.highlightGreen),
          useMaterial3: true,
        ),

        // --- LOGIC ALUR APLIKASI ---
        // Kita set LandingPage sebagai halaman pertama.
        // Nanti LandingPage yang akan mengecek:
        // "Apakah User sudah ada? Jika ya -> Masuk Dashboard. Jika tidak -> Tampilkan Form Nama."
        home: const LandingPage(),
      ),
    );
  }
}
