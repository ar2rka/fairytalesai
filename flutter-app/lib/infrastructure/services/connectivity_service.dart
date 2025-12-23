import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Проверяет наличие подключения к интернету
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Если нет подключения вообще
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Если есть WiFi или мобильная сеть, проверяем реальное подключение
      // Простая проверка - если есть тип подключения, считаем что интернет есть
      // В реальном приложении можно добавить ping к серверу
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      // При ошибке считаем что интернета нет
      return false;
    }
  }

  /// Стрим изменений подключения
  Stream<ConnectivityResult> get connectivityStream => 
      _connectivity.onConnectivityChanged;
}

