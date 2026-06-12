import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/upload_result_model.dart';
import '../providers/upload_provider.dart';

const Map<String, String> _bankOptions = {
  'itau': 'Itaú',
  'santander': 'Santander',
};

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  String? _filePath;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    setState(() {
      _filePath = picked.path;
      _fileName = picked.name;
    });
  }

  void _upload() {
    if (_filePath == null || _fileName == null) return;
    ref.read(uploadControllerProvider.notifier).uploadFile(filePath: _filePath!, fileName: _fileName!);
  }

  void _reset() {
    setState(() {
      _filePath = null;
      _fileName = null;
    });
    ref.read(uploadControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadControllerProvider);

    ref.listen<UploadState>(uploadControllerProvider, (previous, next) {
      if (next.status == UploadStatus.success) {
        ref.invalidate(transactionsProvider);
        ref.invalidate(transactionsSummaryProvider);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Enviar Extrato', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Banco', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final entry in _bankOptions.entries) ...[
                  _BankPill(
                    label: entry.value,
                    selected: uploadState.bank == entry.key,
                    onTap: uploadState.isUploading ? null : () => ref.read(uploadControllerProvider.notifier).setBank(entry.key),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Text('Arquivo PDF', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            InkWell(
              onTap: uploadState.isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(
                      _fileName == null ? Icons.upload_file_rounded : Icons.picture_as_pdf_rounded,
                      color: _fileName == null ? AppColors.muted : AppColors.cyan,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Toque para selecionar um PDF',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _fileName == null ? AppColors.muted : AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 4),
                      const Text('Toque para escolher outro arquivo', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_filePath == null || uploadState.isUploading) ? null : _upload,
              child: uploadState.isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                  : const Text('Enviar'),
            ),
            const SizedBox(height: 24),
            if (uploadState.status == UploadStatus.error) _ErrorCard(message: uploadState.errorMessage ?? 'Erro ao enviar o arquivo.'),
            if (uploadState.status == UploadStatus.success && uploadState.result != null)
              _ResultCard(result: uploadState.result!, onUploadAnother: _reset),
          ],
        ),
      ),
    );
  }
}

class _BankPill extends StatelessWidget {
  const _BankPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withOpacity(0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.cyan : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? AppColors.cyan : AppColors.muted, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expense.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.expense),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.white, fontSize: 14))),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onUploadAnother});

  final UploadResultModel result;
  final VoidCallback onUploadAnother;

  @override
  Widget build(BuildContext context) {
    final isCompleted = result.isCompleted;
    final statusColor = isCompleted ? AppColors.income : AppColors.expense;
    final statusLabel = isCompleted ? 'Processamento concluído' : 'Falha no processamento';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isCompleted ? Icons.check_circle_rounded : Icons.error_rounded, color: statusColor),
                  const SizedBox(width: 10),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              if (!isCompleted && result.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(result.errorMessage!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
              if (isCompleted) ...[
                const SizedBox(height: 16),
                _ResultStat(label: 'Transações importadas', value: '${result.transactionsCreated}'),
                const SizedBox(height: 8),
                _ResultStat(label: 'Duplicadas (ignoradas)', value: '${result.duplicatesSkipped}'),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onUploadAnother,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyan,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Enviar outro'),
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/transactions'),
                        child: const Text('Ver transações'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
