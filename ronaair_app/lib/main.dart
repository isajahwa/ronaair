import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/services/connectivity_service.dart';
import 'presentation/providers/ai_analysis_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/widgets/auto_retry_wrapper.dart';
import 'presentation/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(const RonaAirApp());
}

class RonaAirApp extends StatelessWidget {
  const RonaAirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Stage 12: deteksi online/offline
        ChangeNotifierProvider(create: (_) => ConnectivityService()),

        // Stage 10: state dashboard
        ChangeNotifierProvider(create: (_) => DashboardProvider()),

        // Stage 12: state history
        ChangeNotifierProvider(create: (_) => HistoryProvider()),

        // Stage 13: state AI analysis
        ChangeNotifierProvider(create: (_) => AiAnalysisProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Stage 12: AutoRetryWrapper + OfflineBanner
        builder: (context, child) {
          return AutoRetryWrapper(
            child: OfflineBanner(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const OnboardingScreen(),
      ),
    );
  }
}