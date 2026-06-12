/// Configuração de acesso à API Financily.
///
/// Backend local roda em `uvicorn app.main:app --port 8000` (ver CLAUDE.md).
/// Em desktop (Windows), `localhost` aponta para a máquina local sem
/// restrição de CORS — CORS só se aplica a clientes em navegador.
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
