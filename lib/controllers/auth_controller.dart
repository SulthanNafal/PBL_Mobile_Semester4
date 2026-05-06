import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../utils/hash.dart';

class AuthController {

  final supabase = Supabase.instance.client;

  // ==============================
  // 🔐 NORMALIZE PASSWORD
  // ==============================
  String normalizePassword(
      String password,
      ) {

    return HashCustom.encrypt(
      password.trim(),
    );
  }

  // ==============================
  // 📝 REGISTER
  // ==============================
  Future<String?> register({

    required String username,

    required String email,

    required String password,

  }) async {

    try {

      final hashed =
      normalizePassword(password);

      // ==============================
      // CEK USERNAME
      // ==============================
      final existingUsername =
      await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq(
        'username',
        username.trim(),
      )
          .maybeSingle();

      if (existingUsername != null) {

        return
          "Username sudah pernah terpakai";
      }

      // ==============================
      // CEK EMAIL
      // ==============================
      final existingEmail =
      await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq(
        'email',
        email.trim(),
      )
          .maybeSingle();

      if (existingEmail != null) {

        return
          "Email sudah pernah terpakai";
      }

      // ==============================
      // REGISTER AUTH
      // ==============================
      final res =
      await supabase.auth.signUp(

        email: email.trim(),

        password: hashed,

        emailRedirectTo:
        'com.ursaevent.app://login-callback/',
      );

      final user = res.user;

      if (user == null) {

        return
          "Gagal membuat user";
      }

      // ==============================
      // INSERT TABLE USERS
      // ==============================
      await supabase
          .schema('ursaevent')
          .from('users')
          .insert({

        'id': user.id,

        'username':
        username.trim(),

        'email':
        email.trim(),

        'password':
        hashed,

        'level':
        'user',

        'created_at':
        DateTime.now()
            .toIso8601String(),
      });

      return "success";

    } on AuthException catch (e) {

      return e.message;

    } catch (e) {

      return "Error: $e";
    }
  }

  // ==============================
  // 🔑 LOGIN EMAIL
  // ==============================
  Future<AuthResponse>
  loginWithEmail(
      String email,
      String password,
      ) async {

    final hashed =
    normalizePassword(password);

    return await supabase.auth
        .signInWithPassword(

      email: email.trim(),

      password: hashed,
    );
  }

  // ==============================
  // 📩 SEND RESET PASSWORD EMAIL
  // ==============================
  Future<String?> sendResetPasswordEmail(
      String email,
      ) async {

    try {

      // ==============================
      // CEK EMAIL ADA / TIDAK
      // ==============================
      final userData =
      await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq(
        'email',
        email.trim(),
      )
          .maybeSingle();

      if (userData == null) {

        return
          "Email tidak ditemukan";
      }

      // ==============================
      // KIRIM EMAIL RESET PASSWORD
      // ==============================
      await supabase.auth
          .resetPasswordForEmail(

        email.trim(),

        redirectTo:
        'com.ursaevent.app://reset-password/',
      );

      return "success";

    } on AuthException catch (e) {

      return e.message;

    } catch (e) {

      return "Error: $e";
    }
  }

  // ==============================
  // 🔑 UPDATE PASSWORD BARU
  // ==============================
  Future<String?> updatePassword({

    required String newPassword,

  }) async {

    try {

      final hashed =
      normalizePassword(
          newPassword);

      // ==============================
      // AMBIL USER SESSION SEKARANG
      // ==============================
      final user =
          supabase.auth.currentUser;

      if (user == null) {

        return
          "Session reset password tidak ditemukan";
      }

      // ==============================
      // UPDATE PASSWORD AUTH
      // ==============================
      await supabase.auth.updateUser(

        UserAttributes(
          password: hashed,
        ),
      );

      // ==============================
      // UPDATE PASSWORD TABLE USERS
      // ==============================
      await supabase
          .schema('ursaevent')
          .from('users')
          .update({

        'password': hashed,

      }).eq(
        'id',
        user.id,
      );

      return "success";

    } on AuthException catch (e) {

      return e.message;

    } catch (e) {

      return "Error: $e";
    }
  }

  // ==============================
  // 🔵 LOGIN GOOGLE
  // ==============================
  Future<void> loginWithGoogle() async {

    await supabase.auth
        .signInWithOAuth(

      OAuthProvider.google,

      redirectTo:
      kIsWeb
          ? null
          : 'com.ursaevent.app://login-callback/',
    );
  }

  // ==============================
  // 🚪 LOGOUT
  // ==============================
  Future<void> logout() async {

    await supabase.auth.signOut();
  }
}