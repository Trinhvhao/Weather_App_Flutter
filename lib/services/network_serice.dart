import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static Future<bool> isConnected() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    // Kiểm tra xem có kết nối nào không
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Trả về Stream<List<ConnectivityResult>> để khớp với phiên bản mới
  static Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;
}
