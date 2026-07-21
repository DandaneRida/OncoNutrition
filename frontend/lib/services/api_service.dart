import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/symptome.dart';
import '../models/recette.dart';

/// Service centralisé pour les requêtes HTTP asynchrones liées aux données métier.
class ApiService {
  // Constante définissant le point d'entrée de l'API backend.
  // Note technique : En environnement de développement avec un émulateur Android,
  // la valeur "localhost" doit être remplacée par l'alias "http://10.0.2.2:8000".
  static const String baseUrl = "https://onco-nutrition-beta.vercel.app";

  /// Interroge le serveur pour obtenir le dictionnaire exhaustif des symptômes de référence.
  Future<List<Symptome>> getAllSymptomes() async {
    final url = Uri.parse("$baseUrl/symptomes");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Symptome.fromJson(json)).toList();
      } else {
        throw Exception(
          "Échec de la récupération des données de référence des symptômes.",
        );
      }
    } catch (e) {
      throw Exception("Erreur de communication avec le serveur : $e");
    }
  }

  /// Récupère la liste des symptômes associés au profil de l'utilisateur authentifié.
  Future<List<Symptome>> getUserSymptomes(String token) async {
    final url = Uri.parse("$baseUrl/profil/symptomes");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Symptome.fromJson(json)).toList();
      } else {
        throw Exception(
          "Échec de l'extraction des données cliniques de l'utilisateur.",
        );
      }
    } catch (e) {
      throw Exception("Erreur de communication : $e");
    }
  }

  /// Met à jour la configuration clinique de l'utilisateur en transmettant une nouvelle liste d'identifiants.
  Future<void> updateUserSymptomes(String token, List<int> symptomeIds) async {
    final url = Uri.parse("$baseUrl/profil/symptomes");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"symptome_ids": symptomeIds}),
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ??
              "Échec lors de la persistance de la configuration.",
        );
      }
    } catch (e) {
      throw Exception("Erreur de communication : $e");
    }
  }

  /// Requête l'annuaire des sous-catégories de recettes disponibles dans le système.
  Future<List<String>> getSousCategories() async {
    final url = Uri.parse("$baseUrl/recettes/sous-categories");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<String>.from(data);
      } else {
        throw Exception(
          "Échec de la récupération des classifications de recettes.",
        );
      }
    } catch (e) {
      throw Exception("Erreur de communication : $e");
    }
  }

  /// Génère une liste de recommandations culinaires selon les filtres fournis,
  /// en appliquant l'exclusion stricte des ingrédients contre-indiqués par le profil utilisateur.
  Future<List<Recette>> getRecommendedRecipes(
    String token,
    String? sousCategorie,
    int limite,
  ) async {
    // Élaboration dynamique de l'URL avec encodage des paramètres de requête.
    String urlString = "$baseUrl/profil/recettes-recommandees?limite=$limite";
    if (sousCategorie != null && sousCategorie.isNotEmpty) {
      urlString += "&sous_categorie=${Uri.encodeComponent(sousCategorie)}";
    }

    final url = Uri.parse(urlString);

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Recette.fromJson(json)).toList();
      } else {
        throw Exception(
          "Échec lors du chargement de l'analyse algorithmique des recettes.",
        );
      }
    } catch (e) {
      throw Exception("Erreur de communication avec le serveur : $e");
    }
  }

  /// Sollicite le point de terminaison du profil pour acquérir les métadonnées de l'utilisateur (Identité, Courriel).
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/profil/me');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          "Échec de la lecture des paramètres du compte utilisateur.",
        );
      }
    } catch (e) {
      throw Exception("Erreur de communication avec le serveur : $e");
    }
  }
}
