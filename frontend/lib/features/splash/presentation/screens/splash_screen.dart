import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Tela exibida enquanto [AuthController] restaura a sessão salva
/// (status == [AuthStatus.unknown]). O `redirect` do GoRouter assume o
/// controle assim que a sessão é restaurada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
              ).createShader(rect),
              child: const Text(
                'Financily',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.cyan),
          ],
        ),
      ),
    );
  }
}
