import 'package:flutter/material.dart';
import '../models/recette.dart';
import '../services/api_service.dart';
import '../widgets/custom_bottom_bar.dart';
import 'ingredients_screen.dart';
import 'preparation_screen.dart';

/// Écran principal listant les recettes compatibles après filtrage algorithmique.
class RecipeListScreen extends StatefulWidget {
  final String token;
  final String? sousCategorie;
  final int limite;
  final bool hasSymptom;
  final String? selectedRecipeTitle;
  final String? selectedIngredients;
  final String? selectedPreparation;

  const RecipeListScreen({
    super.key,
    required this.token,
    this.sousCategorie,
    required this.limite,
    this.hasSymptom = false,
    this.selectedRecipeTitle,
    this.selectedIngredients,
    this.selectedPreparation,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final ApiService _apiService = ApiService();

  // Future encapsulant la requête réseau pour l'obtention de la liste de recettes.
  late Future<List<Recette>> _recipesFuture;

  // Variables de gestion de l'état local de consultation.
  String? _activeRecipeTitle;
  String? _activeIngredients;
  String? _activePreparation;

  @override
  void initState() {
    super.initState();
    // Initialisation de la requête réseau selon les paramètres du constructeur.
    _recipesFuture = _apiService.getRecommendedRecipes(
      widget.token,
      widget.sousCategorie,
      widget.limite,
    );
    _activeRecipeTitle = widget.selectedRecipeTitle;
    _activeIngredients = widget.selectedIngredients;
    _activePreparation = widget.selectedPreparation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Résultats de l'analyse"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Utilisation d'un FutureBuilder pour gérer les différents états de la requête asynchrone.
      body: FutureBuilder<List<Recette>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Erreur système : ${snapshot.error.toString().replaceAll("Exception:", "")}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Aucun résultat ne correspond aux critères cliniques et de filtrage.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final recipes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              recipe.sousCategorie,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.science_rounded,
                                size: 14,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${recipe.totalPolyphenols.toStringAsFixed(0)} mg",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        recipe.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text("${recipe.portions} pers."),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.access_time_filled_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(recipe.tempsTotal),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Actions de navigation contextuelle vers les détails (Ingrédients / Méthodologie).
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IngredientsScreen(
                                      token: widget.token,
                                      recipeTitle: recipe.titre,
                                      ingredientsData: recipe.ingredients,
                                      hasSymptom: widget.hasSymptom,
                                      selectedSousCategorie:
                                          widget.sousCategorie,
                                      selectedPreparation: recipe.preparation,
                                      recipeLimit: widget.limite,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.shopping_basket_rounded,
                                size: 18,
                              ),
                              label: const Text("Ingrédients"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: const BorderSide(color: Colors.teal),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PreparationScreen(
                                      token: widget.token,
                                      recipeTitle: recipe.titre,
                                      preparationData: recipe.preparation,
                                      hasSymptom: widget.hasSymptom,
                                      selectedSousCategorie:
                                          widget.sousCategorie,
                                      selectedIngredients: recipe.ingredients,
                                      recipeLimit: widget.limite,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 18,
                              ),
                              label: const Text("Méthodologie"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 2,
        token: widget.token,
        hasSymptom: widget.hasSymptom,
        selectedSousCategorie: widget.sousCategorie,
        selectedRecipeTitle: _activeRecipeTitle,
        selectedIngredients: _activeIngredients,
        selectedPreparation: _activePreparation,
        recipeLimit: widget.limite,
      ),
    );
  }
}
