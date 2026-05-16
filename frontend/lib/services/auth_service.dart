import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  /// Registro: crea usuario en Firebase Auth + documento en Firestore (via backend)
  static Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required String fechaNacimiento,
  }) async {
    // 1. Registrar en el backend (crea en Firebase Auth + Firestore)
    await ApiService.registerUser(
      email: email,
      password: password,
      nombre: nombre,
      fechaNacimiento: fechaNacimiento,
    );

    // 2. Login automático tras registro
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Login con email y contraseña
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Resetear contraseña
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}