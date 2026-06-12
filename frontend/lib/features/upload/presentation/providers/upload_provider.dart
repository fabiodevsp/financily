import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/providers.dart';
import '../../data/models/upload_result_model.dart';
import '../../data/upload_repository.dart';

enum UploadStatus { idle, uploading, success, error }

class UploadState {
  const UploadState({
    this.status = UploadStatus.idle,
    this.bank = 'itau',
    this.fileName,
    this.result,
    this.errorMessage,
  });

  final UploadStatus status;
  final String bank;
  final String? fileName;
  final UploadResultModel? result;
  final String? errorMessage;

  bool get isUploading => status == UploadStatus.uploading;

  UploadState copyWithBank(String bank) => UploadState(
    status: status,
    bank: bank,
    fileName: fileName,
    result: result,
    errorMessage: errorMessage,
  );
}

/// Estado da tela de upload. Não usa `@riverpod` codegen — ver
/// "Decisões arquiteturais" da Fase 4 em docs/project_status.md.
class UploadController extends StateNotifier<UploadState> {
  UploadController(this._repository) : super(const UploadState());

  final UploadRepository _repository;

  void setBank(String bank) => state = state.copyWithBank(bank);

  Future<void> uploadFile({required String filePath, required String fileName}) async {
    state = UploadState(status: UploadStatus.uploading, bank: state.bank, fileName: fileName);
    try {
      final result = await _repository.uploadPdf(filePath: filePath, fileName: fileName, bank: state.bank);
      state = UploadState(status: UploadStatus.success, bank: state.bank, fileName: fileName, result: result);
    } catch (e) {
      state = UploadState(status: UploadStatus.error, bank: state.bank, fileName: fileName, errorMessage: _messageFrom(e));
    }
  }

  void reset() => state = UploadState(bank: state.bank);

  String _messageFrom(Object error) => error is ApiException ? error.message : 'Erro inesperado ao enviar o arquivo.';
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(dioProvider));
});

final uploadControllerProvider = StateNotifierProvider<UploadController, UploadState>((ref) {
  return UploadController(ref.watch(uploadRepositoryProvider));
});
