import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_bottom_bar.dart';
import 'recipe_list_screen.dart';

/// Écran de configuration des filtres de recherche pour les recommandations de recettes.
class PreferencesScreen extends StatefulWidget {
  final String token;
  final bool hasSymptom;
  final String? selectedSousCategorie;
  final String? selectedRecipeTitle;
  final String? selectedIngredients;
  final String? selectedPreparation;
  final int recipeLimit;

  const PreferencesScreen({
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
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final ApiService _apiService = ApiService();

  // États locaux de l'interface.
  List<String> _sousCategories = [];
  String? _selectedSousCategorie;
  double _recipeLimit = 5.0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSousCategorie = widget.selectedSousCategorie;
    _recipeLimit = widget.recipeLimit.toDouble();
    _loadSousCategories();
  }

  /// Requête l'API pour obtenir la liste dynamique des catégories de plats.
  void _loadSousCategories() async {
    try {
      final categories = await _apiService.getSousCategories();
      setState(() {
        _sousCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "");
        _isLoading = false;
      });
    }
  }

  /// Confirme les paramètres et effectue la transition vers l'affichage des résultats.
  void _navigateToRecipes() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeListScreen(
          token: widget.token,
          sousCategorie: _selectedSousCategorie,
          limite: _recipeLimit.round(),
          hasSymptom: widget.hasSymptom,
          selectedRecipeTitle: widget.selectedRecipeTitle,
          selectedIngredients: widget.selectedIngredients,
          selectedPreparation: widget.selectedPreparation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres de filtrage"),
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
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Composant de rappel de l'état global du filtrage.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.hasSymptom
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded,
                              color: widget.hasSymptom
                                  ? Colors.green
                                  : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.hasSymptom
                                  ? "Profil enregistré"
                                  : "Aucun critère actif",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.hasSymptom
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _selectedSousCategorie != null
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded,
                              color: _selectedSousCategorie != null
                                  ? Colors.green
                                  : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedSousCategorie != null
                                  ? "Filtre actif : $_selectedSousCategorie"
                                  : "Recherche globale",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedSousCategorie != null
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Critères de recherche",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Définissez la catégorie cible et le volume de recommandations attendu.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Sélecteur de catégorie.
                  const Text(
                    "Classification du plat (Optionnel)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSousCategorie,
                    hint: const Text("Recherche globale"),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Recherche globale"),
                      ),
                      ..._sousCategories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSousCategorie = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Ajustement du nombre maximal de résultats.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Limite de résultats",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        "${_recipeLimit.round()}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _recipeLimit,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    activeColor: Colors.teal,
                    inactiveColor: Colors.teal.shade100,
                    label: _recipeLimit.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _recipeLimit = value;
                      });
                    },
                  ),
                  const Spacer(),

                  // Bouton d'exécution de la recherche.
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navigateToRecipes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Lancer l'analyse",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
        token: widget.token,
        hasSymptom: widget.hasSymptom,
        selectedSousCategorie: _selectedSousCategorie,
        selectedRecipeTitle: widget.selectedRecipeTitle,
        selectedIngredients: widget.selectedIngredients,
        selectedPreparation: widget.selectedPreparation,
        recipeLimit: _recipeLimit.round(),
      ),
    );
  }
}
