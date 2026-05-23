import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../utils/hash.dart';
import '../main.dart'; // TAMBAHKAN INI

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

      // ======================
      // CEK USERNAME
      // ======================
      final usernameExist =
      await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq(
        'username',
        username.trim(),
      )
          .maybeSingle();

      if (usernameExist != null) {
        return "Username sudah digunakan";
      }

      // ======================
      // CEK EMAIL
      // ======================

      final emailExist =
      await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq(
        'email',
        email.trim(),
      )
          .maybeSingle();

      if (emailExist != null) {

        // akun Google (password masih kosong)
        if (emailExist['password'] == null) {

          final currentUser =
              supabase.auth.currentUser;

          if (currentUser == null) {
            return
              "Silakan login Google terlebih dahulu";
          }

          if (currentUser.email !=
              email.trim()) {
            return
              "Gunakan akun Google yang sama";
          }

          final hashed =
          normalizePassword(
              password);

          // tambah password ke auth user
          await supabase.auth.updateUser(

            UserAttributes(
              password:
              password.trim(),
            ),
          );

          // update data lokal juga
          await supabase
              .schema('ursaevent')
              .from('users')
              .update({

            'password':
            hashed,

            // update username dari form
            'username':
            username.trim(),

            // update nama juga
            'name':
            username.trim(),

          }).eq(
            'id',
            emailExist['id'],
          );

          return
            "Password berhasil ditambahkan";
        }

        return
          "Email sudah terdaftar";
      }

      // ======================
      // REGISTER AUTH
      // ======================
      final response =
      await supabase.auth.signUp(

        email: email.trim(),

        password: password.trim(),

        emailRedirectTo:
        'com.ursaevent.app://login-callback/',
      );

      final user =
          response.user;

      if (user == null) {
        return "Gagal membuat akun";
      }

      // ======================
      // CEK USER DI TABEL
      // ======================
      final existingUser =
      await supabase
          .schema('ursaevent')
          .from('users')
          .select()
          .eq(
        'id',
        user.id,
      )
          .maybeSingle();

      // ======================
      // INSERT USER BARU
      // ======================
      if (existingUser == null) {

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
      }

      return "success";

    }

    on AuthException catch (e) {

      final error =
      e.message.toLowerCase();

      if (error.contains(
          'already registered')) {

        return
          "Email sudah terdaftar";
      }

      return e.message;
    }

    catch (e) {

      return
        "Terjadi kesalahan sistem : $e";
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

      final hashedPassword =
      normalizePassword(password);

      final isEmail =
      loginInput.contains('@');

      dynamic userData;

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

      if (userData == null) {

        return
          "Username/Email atau Password salah";
      }

      await supabase.auth
          .signInWithPassword(

        email: userData['email'],

        password: password.trim(),
      );

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

      if (error.contains(
          'invalid login credentials')) {

        return
          "Username/Email atau Password salah";
      }

      if (error.contains(
          'email not confirmed')) {

        return
          "Email belum diverifikasi";
      }

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
  // 🔵 LOGIN GOOGLE
  // ==============================
  Future<void> loginWithGoogle() async {

    try {

      // FLAG LOGIN GOOGLE
      isGoogleAuth = true;

      await supabase.auth.signInWithOAuth(

        OAuthProvider.google,

        redirectTo:
        kIsWeb
            ? null
            : 'com.ursaevent.app://login-callback/',
      );

    } on AuthException catch (e) {

      isGoogleAuth = false;

      throw Exception(
        "Login Google gagal : ${e.message}",
      );

    } catch (e) {

      isGoogleAuth = false;

      throw Exception(
        "Terjadi kesalahan sistem : $e",
      );
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

      await supabase.auth
          .resetPasswordForEmail(

        email.trim(),

        redirectTo:
        'com.ursaevent.app://reset-password/',
      );

      return "success";

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

      final user =
          supabase.auth.currentUser;

      if (user == null) {

        return
          "Session user tidak ditemukan";
      }

      await supabase.auth.updateUser(

        UserAttributes(
          password:
          newPassword.trim(),
        ),
      );

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

    } catch (e) {

      return
        "Terjadi kesalahan sistem";
    }
  }

  // ==============================
  // 🚪 LOGOUT
  // ==============================
  Future<void> logout() async {

    isGoogleAuth = false;

    await supabase.auth.signOut();
  }
}