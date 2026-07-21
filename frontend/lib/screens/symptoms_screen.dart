import 'package:flutter/material.dart';
import '../models/symptome.dart';
import '../services/api_service.dart';
import '../widgets/custom_bottom_bar.dart';
import 'preferences_screen.dart';

/// Écran dédié à la collecte des symptômes cliniques du patient.
/// Permet l'exclusion ultérieure d'ingrédients contre-indiqués.
class SymptomsScreen extends StatefulWidget {
  final String token;
  final bool hasSymptom;
  final String? selectedSousCategorie;
  final String? selectedRecipeTitle;
  final String? selectedIngredients;
  final String? selectedPreparation;
  final int recipeLimit;

  const SymptomsScreen({
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
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final ApiService _apiService = ApiService();

  List<Symptome> _allSymptomes = [];
  final List<int> _selectedSymptomeIds = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Acquiert la nomenclature complète des symptômes ainsi que la sélection actuelle de l'utilisateur.
  void _loadData() async {
    try {
      final all = await _apiService.getAllSymptomes();
      final userActive = await _apiService.getUserSymptomes(widget.token);

      setState(() {
        _allSymptomes = all;
        _selectedSymptomeIds.addAll(userActive.map((s) => s.idSymptome));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "");
        _isLoading = false;
      });
    }
  }

  /// Enregistre la configuration clinique dans la base de données et opère la transition.
  void _saveAndContinue() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _apiService.updateUserSymptomes(widget.token, _selectedSymptomeIds);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PreferencesScreen(
              token: widget.token,
              hasSymptom: _selectedSymptomeIds.isNotEmpty,
              selectedSousCategorie: widget.selectedSousCategorie,
              selectedRecipeTitle: widget.selectedRecipeTitle,
              selectedIngredients: widget.selectedIngredients,
              selectedPreparation: widget.selectedPreparation,
              recipeLimit: widget.recipeLimit,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur système lors de la persistance des données : $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool currentHasSymptom = _selectedSymptomeIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bilan clinique journalier"),
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Identifiez vos symptômes actuels pour l'exclusion des recommandations non adaptées.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allSymptomes.length,
                    itemBuilder: (context, index) {
                      final symptome = _allSymptomes[index];
                      final isChecked = _selectedSymptomeIds.contains(
                        symptome.idSymptome,
                      );

                      return CheckboxListTile(
                        title: Text(symptome.libelleSymptome),
                        activeColor: Colors.teal,
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedSymptomeIds.add(symptome.idSymptome);
                            } else {
                              _selectedSymptomeIds.remove(symptome.idSymptome);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Valider le bilan et continuer",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        token: widget.token,
        hasSymptom: currentHasSymptom,
        selectedSousCategorie: widget.selectedSousCategorie,
        selectedRecipeTitle: widget.selectedRecipeTitle,
        selectedIngredients: widget.selectedIngredients,
        selectedPreparation: widget.selectedPreparation,
        recipeLimit: widget.recipeLimit,
      ),
    );
  }
}
