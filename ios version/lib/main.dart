import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

  // iOS: Set status bar style for the splash/launch screen
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait on phones (iOS standard for service apps)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

    const orangePrimary = Color(0xFFFF6B00);
    const orangeAccent = Color(0xFFFF8533);
    const grayBgLight = Color(0xFFF2F2F7); // iOS system grouped background
    const grayBgDark = Color(0xFF111215);
    const grayCardDark = Color(0xFF1C1C1E); // iOS dark card color
    const textDark = Color(0xFF1C1C1E);
    const textLight = Color(0xFFE5E7EB);

    // Update status bar color to match dark/light mode
    SystemChrome.setSystemUIOverlayStyle(
      auth.isDarkMode
          ? const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
            ),
    );

    return MaterialApp(
      title: 'LaundryIndia',
      debugShowCheckedModeBanner: false,
      themeMode: auth.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // iOS-tuned Light Theme
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
        textTheme:
            GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).copyWith(
          bodyMedium: GoogleFonts.inter(
              textStyle: const TextStyle(color: textDark)),
          bodyLarge: GoogleFonts.inter(
              textStyle: const TextStyle(color: textDark)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          shadowColor: Colors.black12,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true, // iOS centers titles
          titleTextStyle: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17, // iOS standard nav title size
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: orangePrimary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        dividerColor: const Color(0xFFE5E5EA),
      ),

      // iOS-tuned Dark Theme
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
        textTheme: GoogleFonts.outfitTextTheme(
                Theme.of(context).primaryTextTheme)
            .copyWith(
          bodyMedium: GoogleFonts.inter(
              textStyle: const TextStyle(color: textLight)),
          bodyLarge: GoogleFonts.inter(
              textStyle: const TextStyle(color: textLight)),
        ),
        cardTheme: CardThemeData(
          color: grayCardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF38383A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF38383A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: orangePrimary, width: 1.5),
          ),
          filled: true,
          fillColor: grayCardDark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        dividerColor: const Color(0xFF38383A),
      ),

      // Routes and Guards
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final isAuth = auth.isAuthenticated;
        final isAdmin = auth.isAdmin;
        final routeName = settings.name ?? '/';

        if (routeName == '/') {
          return _iosPageRoute(const LandingPage());
        }
        if (routeName == '/login') {
          if (isAuth) {
            return _iosPageRoute(
                isAdmin ? const AdminDashboardPage() : const DashboardPage());
          }
          return _iosPageRoute(const LoginPage());
        }
        if (routeName == '/dashboard') {
          if (!isAuth) return _iosPageRoute(const LoginPage());
          return _iosPageRoute(const DashboardPage());
        }
        if (routeName == '/book') {
          if (!isAuth) return _iosPageRoute(const LoginPage());
          return _iosPageRoute(const BookingFlowPage());
        }
        if (routeName.startsWith('/track/')) {
          if (!isAuth) return _iosPageRoute(const LoginPage());
          final orderId =
              int.tryParse(routeName.replaceFirst('/track/', '')) ?? 0;
          return _iosPageRoute(TrackingPage(orderId: orderId));
        }
        if (routeName == '/admin') {
          if (!isAuth || !isAdmin) return _iosPageRoute(const LoginPage());
          return _iosPageRoute(const AdminDashboardPage());
        }
        if (routeName == '/admin/pricing') {
          if (!isAuth || !isAdmin) return _iosPageRoute(const LoginPage());
          return _iosPageRoute(const AdminPricingPage());
        }
        if (routeName == '/admin/coupons') {
          if (!isAuth || !isAdmin) return _iosPageRoute(const LoginPage());
          return _iosPageRoute(const AdminCouponsPage());
        }
        return _iosPageRoute(const LandingPage());
      },
    );
  }

  /// iOS-style page transition — slides from right (like UINavigationController)
  PageRoute<T> _iosPageRoute<T>(Widget page) {
    return CupertinoPageRoute<T>(builder: (_) => page);
  }
}
