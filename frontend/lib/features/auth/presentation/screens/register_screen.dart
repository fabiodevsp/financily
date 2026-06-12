import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: _Glow(color: AppColors.purple.withOpacity(0.08), size: 380)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Criar conta',
                      style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Comece a organizar suas finanças com IA.',
                      style: TextStyle(color: AppColors.muted, fontSize: 14)),
                    const SizedBox(height: 32),
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
                              TextFormField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: AppColors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Nome (opcional)',
                                  labelStyle: TextStyle(color: AppColors.muted),
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.muted),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                  if (value == null || value.isEmpty) return 'Informe uma senha';
                                  if (value.length < 8) return 'A senha deve ter ao menos 8 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: true,
                                style: const TextStyle(color: AppColors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Confirmar senha',
                                  labelStyle: TextStyle(color: AppColors.muted),
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.muted),
                                ),
                                validator: (value) {
                                  if (value != _passCtrl.text) return 'As senhas não coincidem';
                                  return null;
                                },
                                onFieldSubmitted: (_) => _register(),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: authState.isLoading ? null : _register,
                                child: authState.isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                                  : const Text('Criar conta'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
    );
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
