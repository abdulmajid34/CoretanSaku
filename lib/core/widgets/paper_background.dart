import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PaperBackground extends StatelessWidget {
  final Widget child;
  // Opsional: jika ingin ganti style kertas nanti
  final bool hasLines;

  const PaperBackground({super.key, required this.child, this.hasLines = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperBackground, // Fallback color
      body: Stack(
        children: [
          // Layer 1: Texture Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.4, // Transparansi agar tidak terlalu harsh
              child: Image.asset(
                'assets/textures/paper_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Jika user belum punya gambar, pakai warna solid saja aman
                  return Container(color: AppColors.paperBackground);
                },
              ),
            ),
          ),

          // Layer 2: Garis-garis buku (Custom Paint) - Optional visual detail
          if (hasLines)
            Positioned.fill(child: CustomPaint(painter: LinedPaperPainter())),

          // Layer 3: Content Utama
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// Helper class untuk menggambar garis buku
class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line.withOpacity(0.3)
      ..strokeWidth = 1.0;

    double lineSpacing = 30.0; // Jarak antar baris
    // Mulai menggambar dari sedikit ke bawah (header area)
    for (double i = 80; i < size.height; i += lineSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Garis pinggir merah (margin kiri) ala buku tulis
    final marginPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(50, 0), Offset(50, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
