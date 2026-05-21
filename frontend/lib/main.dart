import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'models/user_model.dart';
import 'models/transaction_model.dart';
import 'services/user_service.dart';
import 'services/transactions_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/transactions_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Auth Service (load token)
  await UserService.init();

  // If token exists, try to pre-fetch data (swallow errors if server unreachable)
  if (UserService.token != null) {
    try {
      final results = await Future.wait([
        UserService.fetch(),
        TransactionsService.fetch(),
      ]);
      final userData = results[0] as UserData;
      final transactions = results[1] as List<TransactionModel>;
      currentUser.loadFromUserData(userData);
      mockTransactions = transactions;
    } catch (e) {
      debugPrint('Initial data fetch failed: $e');
    }
  }

  runApp(const IvendApp());
}

class IvendApp extends StatelessWidget {
  const IvendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: currentUser,
      child: MaterialApp(
        title: 'ivend',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/signin': (_) => const SignInScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/home': (_) => const HomeScreen(),
          '/transactions': (_) => const TransactionsScreen(),
        },
      ),
    );
  }
}
