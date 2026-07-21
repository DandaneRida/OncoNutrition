import 'package:flutter/material.dart';
import '../widgets/custom_bottom_bar.dart';

/// Écran d'affichage des ingrédients liés à une recette sélectionnée.
/// Composant sans état (StatelessWidget) car les données sont injectées via le constructeur.
class IngredientsScreen extends StatelessWidget {
  // Jeton d'authentification requis pour la persistance de session dans la navigation.
  final String token;

  // Titre de la recette et liste des ingrédients sous forme de chaîne brute.
  final String? recipeTitle;
  final String? ingredientsData;

  // Paramètres de contexte conservés pour le fonctionnement de la barre de navigation.
  final bool hasSymptom;
  final String? selectedSousCategorie;
  final String? selectedPreparation;
  final int recipeLimit;

  const IngredientsScreen({
    super.key,
    required this.token,
    this.recipeTitle,
    this.ingredientsData,
    this.hasSymptom = false,
    this.selectedSousCategorie,
    this.selectedPreparation,
    this.recipeLimit = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingrédients"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 3,
        token: token,
        hasSymptom: hasSymptom,
        selectedSousCategorie: selectedSousCategorie,
        selectedRecipeTitle: recipeTitle,
        selectedIngredients: ingredientsData,
        selectedPreparation: selectedPreparation,
        recipeLimit: recipeLimit,
      ),
    );
  }

  /// Construit le corps de l'écran en gérant l'état de données manquantes.
  Widget _buildBody() {
    // Vérification de la disponibilité des données.
    // Affiche un message d'erreur si aucune recette n'a été préalablement sélectionnée.
    if (recipeTitle == null ||
        ingredientsData == null ||
        ingredientsData!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.kitchen_rounded,
                size: 80,
                color: Colors.teal.shade100,
              ),
              const SizedBox(height: 16),
              const Text(
                "Aucune recette choisie",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Veuillez d'abord sélectionner une recette dans l'onglet 'Recettes' pour voir ses ingrédients.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Traitement de la chaîne d'ingrédients.
    // La séparation s'effectue via le délimiteur "|" défini dans la base de données.
    final List<String> items = ingredientsData!
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête rappelant la recette en cours de consultation.
        Container(
          color: Colors.teal.shade50,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.restaurant_rounded, color: Colors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recipeTitle!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Rendu de la liste d'ingrédients.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
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
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    items[index],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
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
