import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final inicial = (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF1A6B5A).withOpacity(0.12),
            child: Text(
              inicial,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 40,
                color: const Color(0xFF1A6B5A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user?.displayName ?? 'Usuario',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 24, color: const Color(0xFF0D1F1B)),
          ),
          Text(
            user?.email ?? '',
            style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),

          // Info card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? '-',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Email verificado',
                  value: user?.emailVerified == true ? 'Sí' : 'No',
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Cuenta creada',
                  value: user?.metadata.creationTime != null
                      ? '${user!.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Acciones
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined,
                      color: Color(0xFF1A6B5A)),
                  title: Text('Cambiar contraseña',
                      style: GoogleFonts.dmSans(fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () async {
                    if (user?.email != null) {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: user!.email!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Email de recuperación enviado')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: Text('Eliminar cuenta',
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: Colors.red[400])),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey),
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'DiagnósticIA v1.0.0\nSolo orientativo — no sustituye a un médico',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar cuenta',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta acción borrará todos tus datos permanentemente. '
              'Introduce tu contraseña para confirmar.',
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;

              Navigator.pop(ctx); // cierra el diálogo

              try {
                // 1. Llamar al backend para borrar cuenta + datos Firestore
                await ApiService.deleteAccount();
                // 2. Cerrar sesión local
                await FirebaseAuth.instance.signOut();
                // 3. Redirigir al login (navegando a la ruta raíz)
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A6B5A), size: 22),
      title: Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey[500])),
      subtitle: Text(value,
          style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF0D1F1B),
              fontWeight: FontWeight.w500)),
    );
  }
}