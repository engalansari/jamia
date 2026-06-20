import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  static const usernameEmailDomain = 'jamia.local';

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  static String emailForUsername(String username) {
    final normalized = username.trim().toLowerCase();
    return '$normalized@$usernameEmailDomain';
  }

  Future<UserCredential> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) {
    return signInWithEmailAndPassword(
      email: emailForUsername(username),
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
