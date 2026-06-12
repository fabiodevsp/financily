import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.expense),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(top: -100, left: -80, child: _Glow(color: AppColors.cyan.withOpacity(0.08), size: 400)),
          Positioned(bottom: -60, right: -80, child: _Glow(color: AppColors.purple.withOpacity(0.08), size: 350)),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
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
                      const SizedBox(height: 64),
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
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: AppColors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                    labelStyle: TextStyle(color: AppColors.muted),
                                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Informe seu e-mail';
                                    if (!value.contains('@')) return 'E-mail inválido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: true,
                                  style: const TextStyle(color: AppColors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Senha',
                                    labelStyle: TextStyle(color: AppColors.muted),
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.muted),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Informe sua senha';
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _login(),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: authState.isLoading ? null : _login,
                                  child: authState.isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                                    : const Text('Entrar'),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: authState.isLoading ? null : () => context.push('/register'),
                                    child: const Text('Não tem conta? Criar conta', style: TextStyle(color: AppColors.cyan)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
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
