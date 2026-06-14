import 'package:get_it/get_it.dart';
import 'package:mongez/features/auth/repos/auth_repo_implementation.dart';
import 'package:mongez/features/auth/repos/governorates_repo.dart';
import 'package:mongez/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:mongez/features/favorites/domain/favorites_repository.dart';
import 'package:mongez/features/home/repos/home_repo.dart';
import 'package:mongez/features/home/repos/home_repo_implementation.dart';
import 'package:mongez/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mongez/features/notifications/domain/notification_repository.dart';
import 'package:mongez/features/orders/data/repositories/order_repository_impl.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';
import 'package:mongez/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mongez/features/profile/domain/profile_repository.dart';
import 'package:mongez/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';
import 'package:mongez/services/api_client.dart';
import 'package:mongez/services/api_service.dart';

final getIt = GetIt.instance;

void setup() {
  final apiService = ApiService(DioClient());
  getIt.registerLazySingleton<ApiService>(() => apiService);

  // Auth
  getIt.registerLazySingleton(
    () => AuthRepoImplementation(getIt.get<ApiService>()),
  );
  getIt.registerLazySingleton<GovernoratesRepo>(
    () => GovernoratesRepo(getIt.get<ApiService>()),
  );

  // Home / Categories
  getIt.registerLazySingleton<HomeRepo>(
    () => HomeRepoImplementation(getIt.get<ApiService>()),
  );

  // Workers
  getIt.registerLazySingleton<WorkerRepository>(
    () => WorkerRepositoryImpl(getIt.get<ApiService>()),
  );

  // Orders
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(getIt.get<ApiService>()),
  );

  // Favorites
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(getIt.get<ApiService>()),
  );

  // Profile
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt.get<ApiService>()),
  );

  // Notifications
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(getIt.get<ApiService>()),
  );
}
