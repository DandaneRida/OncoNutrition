import 'package:flutter/material.dart';
import '../models/symptome.dart';
import '../services/api_service.dart';
import '../widgets/custom_bottom_bar.dart';
import 'login_screen.dart';

/// Écran de consultation des informations du profil et de l'état clinique actuel.
class ProfileScreen extends StatefulWidget {
  final String token;
  final bool hasSymptom;
  final String? selectedSousCategorie;
  final String? selectedRecipeTitle;
  final String? selectedIngredients;
  final String? selectedPreparation;
  final int recipeLimit;

  const ProfileScreen({
    super.key,
    required this.token,
    this.hasSymptom = false,
    this.selectedSousCategorie,
    this.selectedRecipeTitle,
    this.selectedIngredients,
    this.selectedPreparation,
    this.recipeLimit = 5,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  List<Symptome> _mySymptoms = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Stockage des informations d'identité.
  String _nomPatient = "";
  String _emailPatient = "";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Chargement asynchrone des données du profil et de l'état clinique.
  void _loadProfileData() async {
    try {
      // Extraction des données personnelles.
      final profileData = await _apiService.getUserProfile(widget.token);
      _nomPatient = profileData['nom'] ?? 'Identifiant inconnu';
      _emailPatient = profileData['email'] ?? 'Adresse non spécifiée';

      // Extraction des symptômes déclarés.
      final symptoms = await _apiService.getUserSymptomes(widget.token);

      if (mounted) {
        setState(() {
          _mySymptoms = symptoms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception:", "");
          _isLoading = false;
        });
      }
    }
  }

  /// Invalidation de la session et retour à l'écran d'authentification.
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Espace Utilisateur"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Affichage des informations de l'entité.
                  Text(
                    _nomPatient,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailPatient,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Affichage conditionnel selon la présence de symptômes.
                  _mySymptoms.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Aucune condition clinique contraignante signalée.",
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _mySymptoms.map((symptom) {
                            return Chip(
                              label: Text(symptom.libelleSymptome),
                              backgroundColor: Colors.orange.shade50,
                              labelStyle: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide(color: Colors.orange.shade200),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 40),

                  // Déclencheur de fin de session.
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text("Déconnexion"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 5,
        token: widget.token,
        hasSymptom: _mySymptoms.isNotEmpty || widget.hasSymptom,
        selectedSousCategorie: widget.selectedSousCategorie,
        selectedRecipeTitle: widget.selectedRecipeTitle,
        selectedIngredients: widget.selectedIngredients,
        selectedPreparation: widget.selectedPreparation,
        recipeLimit: widget.recipeLimit,
      ),
    );
  }
}
