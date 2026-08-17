import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  static Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": userCred.user!.email,
          "name": userCred.user!.displayName,
        }),
      );

      print("Google Login Status: ${response.statusCode}");
      print("Google Login Body: ${response.body}");

      if (response.statusCode == 200) {
        ApiService.token = jsonDecode(response.body)["access_token"];
        return userCred.user;
      }

      return null;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }
}
