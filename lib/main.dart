import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/seller/seller_dashboard_screen.dart';
import 'screens/buyer/buyer_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Marketplace App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authService.currentUser == null) {
      return const LoginScreen();
    }

    // Role based routing
    switch (authService.userRole) {
      case 'admin':
        return Scaffold(
          appBar: AppBar(title: const Text('Admin Dashboard'), actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () => authService.logout())
          ]),
          body: const Center(child: Text('Admin Control Panel')),
        );
      case 'seller':
        return const SellerDashboardScreen();
      case 'buyer':
      default:
        return const BuyerHomeScreen();
    }
  }
}
