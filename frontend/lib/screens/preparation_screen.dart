import 'package:flutter/material.dart';
import '../widgets/custom_bottom_bar.dart';

/// Écran d'affichage des instructions de préparation d'une recette.
class PreparationScreen extends StatelessWidget {
  final String token;
  final String? recipeTitle;
  final String? preparationData;
  final bool hasSymptom;
  final String? selectedSousCategorie;
  final String? selectedIngredients;
  final int recipeLimit;

  const PreparationScreen({
    super.key,
    required this.token,
    this.recipeTitle,
    this.preparationData,
    this.hasSymptom = false,
    this.selectedSousCategorie,
    this.selectedIngredients,
    this.recipeLimit = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Méthodologie"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 4,
        token: token,
        hasSymptom: hasSymptom,
        selectedSousCategorie: selectedSousCategorie,
        selectedRecipeTitle: recipeTitle,
        selectedIngredients: selectedIngredients,
        selectedPreparation: preparationData,
        recipeLimit: recipeLimit,
      ),
    );
  }

  /// Traitement et rendu de la vue principale.
  Widget _buildBody() {
    // Vérification contextuelle : nécessité d'une sélection préalable.
    if (recipeTitle == null ||
        preparationData == null ||
        preparationData!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.list_alt_rounded,
                size: 80,
                color: Colors.orange.shade100,
              ),
              const SizedBox(height: 16),
              const Text(
                "Données non disponibles",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Sélectionnez une recette valide dans l'annuaire pour accéder aux instructions de préparation.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Analyse et segmentation de la chaîne d'instructions.
    final List<String> steps = preparationData!
        .split('|')
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicateur du contexte de la recette.
        Container(
          color: Colors.orange.shade50,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recipeTitle!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Rendu séquentiel des étapes.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    steps[index],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
