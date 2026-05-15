import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(top: -100, left: -80, child: _Glow(color: AppColors.cyan.withOpacity(0.08), size: 400)),
          Positioned(bottom: -60, right: -80, child: _Glow(color: AppColors.purple.withOpacity(0.08), size: 350)),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [AppColors.cyan, AppColors.purple],
                      ).createShader(r),
                      child: const Text('Financily',
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Sua inteligência financeira com IA.',
                      style: TextStyle(color: AppColors.muted, fontSize: 16)),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.card.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Entrar', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _emailCtrl,
                                style: const TextStyle(color: AppColors.white),
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  labelStyle: TextStyle(color: AppColors.muted),
                                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passCtrl,
                                obscureText: true,
                                style: const TextStyle(color: AppColors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  labelStyle: TextStyle(color: AppColors.muted),
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.muted),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loading ? null : _login,
                                child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                                  : const Text('Entrar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _login() {
    setState(() => _loading = true);
    // TODO: call auth provider
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go('/dashboard');
    });
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()),
  );
}
