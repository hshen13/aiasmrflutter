import 'package:get_it/get_it.dart';
import '../api/api_client.dart';
import '../storage/storage_service.dart';
import '../storage/shared_preferences_service.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Storage
  final storageService = SharedPreferencesService();
  await storageService.init();
  getIt.registerSingleton<StorageService>(storageService);
  getIt.registerSingleton<SharedPreferencesService>(storageService);

  // Network
  final dioClient = DioClient(getIt<StorageService>());
  getIt.registerSingleton<DioClient>(dioClient);
  getIt.registerSingleton<ApiClient>(ApiClient(dioClient));
}
