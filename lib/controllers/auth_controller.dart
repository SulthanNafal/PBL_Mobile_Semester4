import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../utils/hash.dart';

class AuthController {

  final supabase = Supabase.instance.client;

  // ==============================
  // 🔐 HASH CUSTOM
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

        return "Username sudah digunakan";
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

        return "Email sudah digunakan";
      }

      // ==============================
      // REGISTER AUTH
      // ==============================
      final res =
      await supabase.auth.signUp(

        email: email.trim(),

        password: password.trim(),

        emailRedirectTo:
        'com.ursaevent.app://login-callback/',
      );

      final user = res.user;

      if (user == null) {

        return "Gagal membuat akun";
      }

      // ==============================
      // INSERT USERS TABLE
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

      final error =
      e.message.toLowerCase();

      if (error.contains(
          'already registered')) {

        return "Email sudah digunakan";
      }

      return "Registrasi gagal";

    } catch (e) {

      return "Terjadi kesalahan sistem";
    }
  }

  // ==============================
  // 🔑 LOGIN USERNAME / EMAIL
  // ==============================
  Future<dynamic> loginWithEmail(

      String loginInput,
      String password,

      ) async {

    try {

      // ==============================
      // HASH PASSWORD CUSTOM
      // ==============================
      final hashedPassword =
      normalizePassword(password);

      // ==============================
      // DETEKSI EMAIL / USERNAME
      // ==============================
      final isEmail =
      loginInput.contains('@');

      dynamic userData;

      // ==============================
      // LOGIN VIA EMAIL
      // ==============================
      if (isEmail) {

        userData =
        await supabase
            .schema('ursaevent')
            .from('users')
            .select()
            .eq(
          'email',
          loginInput.trim(),
        )
            .eq(
          'password',
          hashedPassword,
        )
            .maybeSingle();

      } else {

        // ==============================
        // LOGIN VIA USERNAME
        // ==============================
        userData =
        await supabase
            .schema('ursaevent')
            .from('users')
            .select()
            .eq(
          'username',
          loginInput.trim(),
        )
            .eq(
          'password',
          hashedPassword,
        )
            .maybeSingle();
      }

      // ==============================
      // USER TIDAK DITEMUKAN
      // ==============================
      if (userData == null) {

        return
          "Username/Email atau Password salah";
      }

      // ==============================
      // LOGIN SUPABASE AUTH
      // ==============================
      await supabase.auth
          .signInWithPassword(

        email: userData['email'],

        password: password.trim(),
      );

      // ==============================
      // RETURN USER DATA
      // ==============================
      return {

        'status': 'success',

        'level':
        userData['level'],

        'user':
        userData,
      };

    } on AuthException catch (e) {

      final error =
      e.message.toLowerCase();

      // ==============================
      // INVALID LOGIN
      // ==============================
      if (error.contains(
          'invalid login credentials')) {

        return
          "Username/Email atau Password salah";
      }

      // ==============================
      // EMAIL BELUM VERIFIKASI
      // ==============================
      if (error.contains(
          'email not confirmed')) {

        return
          "Email belum diverifikasi";
      }

      // ==============================
      // TOO MANY REQUEST
      // ==============================
      if (error.contains(
          'too many requests')) {

        return
          "Terlalu banyak percobaan login";
      }

      return "Login gagal";

    } catch (e) {

      return
        "Terjadi kesalahan sistem\n$e";
    }
  }

  // ==============================
  // 📩 RESET PASSWORD EMAIL
  // ==============================
  Future<String?> sendResetPasswordEmail(

      String email,

      ) async {

    try {

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
      // SEND RESET EMAIL
      // ==============================
      await supabase.auth
          .resetPasswordForEmail(

        email.trim(),

        redirectTo:
        'com.ursaevent.app://reset-password/',
      );

      return "success";

    } on AuthException catch (e) {

      final error =
      e.message.toLowerCase();

      if (error.contains(
          'email rate limit exceeded')) {

        return
          "Terlalu banyak permintaan";
      }

      return
        "Gagal mengirim link reset password";

    } catch (e) {

      return
        "Terjadi kesalahan sistem";
    }
  }

  // ==============================
  // 🔑 UPDATE PASSWORD
  // ==============================
  Future<String?> updatePassword({

    required String newPassword,

  }) async {

    try {

      final hashed =
      normalizePassword(
        newPassword,
      );

      // ==============================
      // SESSION USER
      // ==============================
      final user =
          supabase.auth.currentUser;

      if (user == null) {

        return
          "Session user tidak ditemukan";
      }

      // ==============================
      // UPDATE AUTH PASSWORD
      // ==============================
      await supabase.auth.updateUser(

        UserAttributes(
          password:
          newPassword.trim(),
        ),
      );

      // ==============================
      // UPDATE USERS TABLE
      // ==============================
      await supabase
          .schema('ursaevent')
          .from('users')
          .update({

        'password':
        hashed,

      }).eq(
        'id',
        user.id,
      );

      return "success";

    } on AuthException catch (e) {

      final error =
      e.message.toLowerCase();

      if (error.contains(
          'same password')) {

        return
          "Password baru tidak boleh sama";
      }

      return
        "Gagal mengubah password";

    } catch (e) {

      return
        "Terjadi kesalahan sistem";
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