import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

/// Service exclusif au traitement des authentifications et du provisionnement de comptes.
class AuthService {
  static const String baseUrl = "https://onco-nutrition-beta.vercel.app";

  /// Exécute la procédure de création d'un nouveau compte utilisateur.
  Future<User?> signup(String nom, String email, String password) async {
    final url = Uri.parse("$baseUrl/signup");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nom": nom, "email": email, "password": password}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ?? "Anomalie lors de la procédure d'inscription.",
        );
      }
    } catch (e) {
      throw Exception("Défaillance de l'infrastructure réseau ou serveur : $e");
    }
  }

  /// Gère le processus d'authentification et l'acquisition du jeton d'accès sécurisé.
  Future<String> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {
          // Entête obligatoirement défini pour l'interopérabilité avec les protocoles de sécurité de FastAPI.
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          // Injection des identifiants (l'architecture FastAPI impose l'usage de la nomenclature "username").
          "username": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['detail'] ?? "Refus d'authentification par le serveur.",
        );
      }
    } catch (e) {
      throw Exception("Défaillance de l'infrastructure réseau ou serveur : $e");
    }
  }
}
