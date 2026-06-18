import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mongez/core/app_themes.dart';
import 'package:mongez/core/bloc/cubit/localization_cubit.dart';
import 'package:mongez/core/bloc/theme_cubit/theme_cubit.dart';
import 'package:mongez/core/helpers.dart';
import 'package:mongez/features/auth/bloc/register_cubit/register_cubit.dart';
import 'package:mongez/features/auth/bloc/login_cubit/auth_cubit.dart';
import 'package:mongez/features/auth/repos/auth_repo_implementation.dart';
import 'package:mongez/features/auth/screens/get_started_screen.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/models/user.dart';
import 'package:mongez/features/auth/models/tokens.dart';
import 'package:mongez/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/favorites/domain/favorites_repository.dart';
import 'package:mongez/features/home/bloc/categories_cubit/categories_cubit.dart';
import 'package:mongez/features/home/repos/home_repo.dart';
import 'package:mongez/services/navigation_service.dart';
import 'package:mongez/features/orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/job_history_cubit.dart';
import 'package:mongez/features/orders/presentation/cubit/checkout_cubit.dart';
import 'package:mongez/features/notifications/domain/notification_repository.dart';
import 'package:mongez/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';
import 'package:mongez/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/profile/domain/profile_repository.dart';
import 'package:mongez/features/workers/presentation/cubit/create_worker_profile_cubit.dart';
import 'package:mongez/features/workers/presentation/cubit/worker_stats_cubit.dart';
import 'package:mongez/features/workers/presentation/cubit/workers_cubit.dart';
import 'package:mongez/features/workers/domain/worker_repository.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/services/services_locator.dart';
import 'package:mongez/services/helper.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setup();
  await AppPrefs.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit(context)),
            BlocProvider(create: (_) => LocalizationCubit()),
            BlocProvider(
              create: (context) =>
                  LoginCubit(authRepo: getIt.get<AuthRepoImplementation>()),
            ),
            BlocProvider(
              create: (context) =>
                  RegisterCubit(authRepo: getIt.get<AuthRepoImplementation>()),
            ),
            BlocProvider(
              create: (context) =>
                  CategoriesCubit(homeRepo: getIt.get<HomeRepo>())
                    ..fetchCategories(),
            ),
            BlocProvider(
              create: (context) =>
                  WorkersCubit(workerRepository: getIt.get<WorkerRepository>())
                    ..refresh(),
            ),
            BlocProvider(
              create: (context) =>
                  ProfileCubit(profileRepository: getIt.get<ProfileRepository>())
                    ..getProfile()
                    ..startPolling(),
            ),
            BlocProvider(
              create: (context) => CustomerOrdersCubit(
                orderRepository: getIt.get<OrderRepository>(),
              )..getOrders(),
            ),
            BlocProvider(
              create: (context) => TechnicianOrdersCubit(
                orderRepository: getIt.get<OrderRepository>(),
              )..getOrders(),
            ),
            BlocProvider(
              create: (context) => JobHistoryCubit(
                orderRepository: getIt.get<OrderRepository>(),
              )..getJobHistory(),
            ),
            BlocProvider(
              create: (context) => CheckoutCubit(
                orderRepository: getIt.get<OrderRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => FavoritesCubit(
                favoritesRepository: getIt.get<FavoritesRepository>(),
              )..getFavorites(),
            ),
            BlocProvider(
              create: (context) => CreateWorkerProfileCubit(
                workerRepository: getIt.get<WorkerRepository>(),
              ),
            ),
            // Worker stats — loaded lazily on the worker home screen
            // (the request 404s for client/admin users, so we don't
            // hit it eagerly here).
            BlocProvider(
              create: (context) => WorkerStatsCubit(
                workerRepository: getIt.get<WorkerRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => NotificationCubit(
                notificationRepository: getIt.get<NotificationRepository>(),
              ),
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocalizationCubit, LocalizationState>(
                builder: (context, localeState) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppThemes.lightTheme,
                    darkTheme: AppThemes.darkTheme,
                    themeMode: themeState.themeMode,
                    locale: localeState.locale,
                    localizationsDelegates: [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: S.delegate.supportedLocales,
                    localeResolutionCallback: (
                      Locale? locale,
                      Iterable<Locale> supportedLocales,
                    ) {
                      if (locale != null) {
                        for (final supported in supportedLocales) {
                          if (supported.languageCode == locale.languageCode) {
                            return supported;
                          }
                        }
                      }
                      return const Locale('en');
                    },
                    home: const AppStartupScreen(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    String? token = await PrefHelper.getToken();
    if (token == null || token.isEmpty) {
      _goToAuthFlow();
      return;
    }
    try {
      final profileRepo = getIt.get<ProfileRepository>();
      final result = await profileRepo.getProfile();
      result.fold(
        (_) async {
          final refreshed = await _tryRefreshToken();
          if (!refreshed) {
            _goToAuthFlow();
            return;
          }
          final newToken = await PrefHelper.getToken();
          if (newToken == null) {
            _goToAuthFlow();
            return;
          }
          final retry = await profileRepo.getProfile();
          retry.fold(
            (_) => _goToAuthFlow(),
            (profile) => _goToMain(profile, newToken),
          );
        },
        (profile) => _goToMain(profile, token),
      );
    } catch (_) {
      _goToAuthFlow();
    }
  }

  void _goToMain(dynamic profile, String token) {
    final user = User(
      id: profile.id,
      username: profile.username,
      nameAr: profile.nameAr,
      displayName: profile.displayName,
      phone: profile.phone,
      address: profile.address,
      governorate: profile.governorate,
      governorateLabel: profile.governorateLabel,
      city: profile.city,
      profileImage: profile.profileImage,
      role: profile.role,
      dateJoined: profile.dateJoined != null
        ? DateTime.tryParse(profile.dateJoined!)
        : null,
    );
    final auth = Auth(
      message: '',
      user: user,
      tokens: Tokens(access: token),
    );
    _goToMainScreen(auth);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await PrefHelper.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await Dio(
        BaseOptions(baseUrl: ApiConstants.baseUrl),
      ).post(
        Endpoints.refreshToken,
        data: {'refresh': refreshToken},
      );
      final newAccess = response.data['access'] as String?;
      if (newAccess != null) {
        await PrefHelper.saveToken(newAccess);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _goToMainScreen(Auth auth) {
    if (!mounted) return;
    NavigationService.toMainScreen(context, auth);
  }

  void _goToAuthFlow() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

//.\venv\Scripts\python.exe manage.py runserver