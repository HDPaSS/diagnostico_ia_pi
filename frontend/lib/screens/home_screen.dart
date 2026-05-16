import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'predict/predict_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PredictScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        title: Text(
          _currentIndex == 0
              ? 'DiagnósticIA'
              : _currentIndex == 1
                  ? 'Historial'
                  : 'Perfil',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            color: const Color(0xFF0D1F1B),
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1A6B5A).withOpacity(0.1),
                radius: 18,
                child: Text(
                  (user?.displayName ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1A6B5A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentIndex == 2)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A6B5A)),
              onPressed: () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAF9),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A6B5A).withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            selectedIcon: const Icon(Icons.search_rounded, color: Color(0xFF1A6B5A)),
            label: 'Diagnóstico',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            selectedIcon: const Icon(Icons.history_rounded, color: Color(0xFF1A6B5A)),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded, color: Color(0xFF1A6B5A)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}