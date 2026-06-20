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

    // Color definitions matching CSS variables
    const primaryDark = Color(0xFF021024);
    const accentLight = Color(0xFF7DA0CA);
    const bgLight = Color(0xFFF5F8FC);
    const bgDark = Color(0xFF021024);
    const cardDark = Color(0xFF051630);

    return MaterialApp(
      title: 'LaundryIndia Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: auth.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: bgLight,
        primaryColor: primaryDark,
        colorScheme: const ColorScheme.light(
          primary: primaryDark,
          secondary: accentLight,
          surface: Colors.white,
          error: Colors.red,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).copyWith(
          bodyMedium: GoogleFonts.inter(textStyle: const TextStyle(color: primaryDark)),
          bodyLarge: GoogleFonts.inter(textStyle: const TextStyle(color: primaryDark)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: primaryDark,
          elevation: 0,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        primaryColor: accentLight,
        colorScheme: const ColorScheme.dark(
          primary: accentLight,
          secondary: accentLight,
          surface: cardDark,
          error: Colors.red,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).primaryTextTheme).copyWith(
          bodyMedium: GoogleFonts.inter(textStyle: const TextStyle(color: Color(0xFFF0F4F9))),
          bodyLarge: GoogleFonts.inter(textStyle: const TextStyle(color: Color(0xFFF0F4F9))),
        ),
        cardTheme: CardThemeData(
          color: cardDark,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cardDark,
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
