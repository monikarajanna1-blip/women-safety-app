 import 'package:firebase_auth/firebase_auth.dart';
 import '../services/fcm_service.dart';

class AuthService {
  Future<String?> login(String email, String password) async {
    try {
      UserCredential cred=
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
       if (cred.user != null) {
    await FCMService.saveToken(cred.user!.uid);
  }

      return null; // success
    } on FirebaseAuthException catch (e) {
      print("LOGIN ERROR: ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      print("UNKNOWN LOGIN ERROR: $e");
      return "Something went wrong";
    }
  }


  Future<String?> signup(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
