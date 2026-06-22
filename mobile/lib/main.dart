import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'store/auth_provider.dart';
import 'store/cart_provider.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/booking_flow_page.dart';
import 'pages/tracking_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_pricing_page.dart';
import 'pages/admin_coupons_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const LaundryIndiaApp(),
    ),
  );
}

class LaundryIndiaApp extends StatelessWidget {
  const LaundryIndiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Color definitions matching Gray/Orange color scheme
    const orangePrimary = Color(0xFFFF6B00);
    const orangeAccent = Color(0xFFFF8533);
    const grayBgLight = Color(0xFFF3F4F6);
    const grayBgDark = Color(0xFF111215);
    const grayCardDark = Color(0xFF1E2024);
    const textDark = Color(0xFF1F2937);
    const textLight = Color(0xFFE5E7EB);

    return MaterialApp(
      title: 'LaundryIndia Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: auth.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: grayBgLight,
        primaryColor: orangePrimary,
        colorScheme: const ColorScheme.light(
          primary: orangePrimary,
          secondary: orangeAccent,
          surface: Colors.white,
          error: Colors.red,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).copyWith(
          bodyMedium: GoogleFonts.inter(textStyle: const TextStyle(color: textDark)),
          bodyLarge: GoogleFonts.inter(textStyle: const TextStyle(color: textDark)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: grayBgDark,
        primaryColor: orangePrimary,
        colorScheme: const ColorScheme.dark(
          primary: orangePrimary,
          secondary: orangeAccent,
          surface: grayCardDark,
          error: Colors.red,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).primaryTextTheme).copyWith(
          bodyMedium: GoogleFonts.inter(textStyle: const TextStyle(color: textLight)),
          bodyLarge: GoogleFonts.inter(textStyle: const TextStyle(color: textLight)),
        ),
        cardTheme: CardThemeData(
          color: grayCardDark,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: grayCardDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // Routes and Guards
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Authenticated router guard logic
        final isAuth = auth.isAuthenticated;
        final isAdmin = auth.isAdmin;
        final routeName = settings.name ?? '/';

        // Direct paths mapping
        if (routeName == '/') {
          return MaterialPageRoute(builder: (_) => const LandingPage());
        }
        if (routeName == '/login') {
          if (isAuth) {
            return MaterialPageRoute(
              builder: (_) => isAdmin ? const AdminDashboardPage() : const DashboardPage(),
            );
          }
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }

        // Customer routes
        if (routeName == '/dashboard') {
          if (!isAuth) return MaterialPageRoute(builder: (_) => const LoginPage());
          return MaterialPageRoute(builder: (_) => const DashboardPage());
        }
        if (routeName == '/book') {
          if (!isAuth) return MaterialPageRoute(builder: (_) => const LoginPage());
          return MaterialPageRoute(builder: (_) => const BookingFlowPage());
        }
        if (routeName.startsWith('/track/')) {
          if (!isAuth) return MaterialPageRoute(builder: (_) => const LoginPage());
          final orderId = int.tryParse(routeName.replaceFirst('/track/', '')) ?? 0;
          return MaterialPageRoute(builder: (_) => TrackingPage(orderId: orderId));
        }

        // Admin routes
        if (routeName == '/admin') {
          if (!isAuth || !isAdmin) return MaterialPageRoute(builder: (_) => const LoginPage());
          return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
        }
        if (routeName == '/admin/pricing') {
          if (!isAuth || !isAdmin) return MaterialPageRoute(builder: (_) => const LoginPage());
          return MaterialPageRoute(builder: (_) => const AdminPricingPage());
        }
        if (routeName == '/admin/coupons') {
          if (!isAuth || !isAdmin) return MaterialPageRoute(builder: (_) => const LoginPage());
          return MaterialPageRoute(builder: (_) => const AdminCouponsPage());
        }

        // Fallback default redirect to home
        return MaterialPageRoute(builder: (_) => const LandingPage());
      },
    );
  }
}
