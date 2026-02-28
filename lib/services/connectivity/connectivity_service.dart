import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxController {
  final _connectivity = Connectivity();

  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      isConnected.value = !results.contains(ConnectivityResult.none);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    isConnected.value = !results.contains(ConnectivityResult.none);
  }

  bool get isOnline => isConnected.value;
  bool get isOffline => !isConnected.value;
}
