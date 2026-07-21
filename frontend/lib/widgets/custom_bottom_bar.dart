import 'package:flutter/material.dart';
import '../screens/symptoms_screen.dart';
import '../screens/preferences_screen.dart';
import '../screens/recipe_list_screen.dart';
import '../screens/ingredients_screen.dart';
import '../screens/preparation_screen.dart';
import '../screens/profile_screen.dart';

/// Composant de navigation transversale (Bottom Navigation Bar).
/// Assure la transition entre les différents modules de l'application tout en préservant le contexte d'état global.
class CustomBottomBar extends StatelessWidget {
  // Index du module actuellement actif.
  final int currentIndex;

  // Jeton d'authentification pour le maintien de session.
  final String token;

  // Paramètres assurant la conservation du contexte de navigation et des critères de recherche entre les écrans.
  final bool hasSymptom;
  final String? selectedSousCategorie;
  final String? selectedRecipeTitle;
  final String? selectedIngredients;
  final String? selectedPreparation;
  final int recipeLimit;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.token,
    this.hasSymptom = false,
    this.selectedSousCategorie,
    this.selectedRecipeTitle,
    this.selectedIngredients,
    this.selectedPreparation,
    this.recipeLimit = 5,
  });

  /// Gère l'événement de sélection d'un onglet et exécute la redirection appropriée vers le module ciblé.
  void _onItemTapped(BuildContext context, int index) {
    // Interruption de la routine si l'utilisateur sélectionne l'onglet actuellement instancié.
    if (index == currentIndex) return;

    Widget nextScreen;

    // Détermination de la vue de destination selon l'index d'interaction.
    switch (index) {
      case 0:
        nextScreen = SymptomsScreen(
          token: token,
          hasSymptom: hasSymptom,
          selectedSousCategorie: selectedSousCategorie,
          selectedRecipeTitle: selectedRecipeTitle,
          selectedIngredients: selectedIngredients,
          selectedPreparation: selectedPreparation,
          recipeLimit: recipeLimit,
        );
        break;
      case 1:
        nextScreen = PreferencesScreen(
          token: token,
          hasSymptom: hasSymptom,
          selectedSousCategorie: selectedSousCategorie,
          selectedRecipeTitle: selectedRecipeTitle,
          selectedIngredients: selectedIngredients,
          selectedPreparation: selectedPreparation,
          recipeLimit: recipeLimit,
        );
        break;
      case 2:
        nextScreen = RecipeListScreen(
          token: token,
          sousCategorie: selectedSousCategorie,
          limite: recipeLimit,
          hasSymptom: hasSymptom,
          selectedRecipeTitle: selectedRecipeTitle,
          selectedIngredients: selectedIngredients,
          selectedPreparation: selectedPreparation,
        );
        break;
      case 3:
        nextScreen = IngredientsScreen(
          token: token,
          recipeTitle: selectedRecipeTitle,
          ingredientsData: selectedIngredients,
          hasSymptom: hasSymptom,
          selectedSousCategorie: selectedSousCategorie,
          selectedPreparation: selectedPreparation,
          recipeLimit: recipeLimit,
        );
        break;
      case 4:
        nextScreen = PreparationScreen(
          token: token,
          recipeTitle: selectedRecipeTitle,
          preparationData: selectedPreparation,
          hasSymptom: hasSymptom,
          selectedSousCategorie: selectedSousCategorie,
          selectedIngredients: selectedIngredients,
          recipeLimit: recipeLimit,
        );
        break;
      case 5:
        // Module de consultation du profil et de gestion de l'entité utilisateur.
        nextScreen = ProfileScreen(
          token: token,
          hasSymptom: hasSymptom,
          selectedSousCategorie: selectedSousCategorie,
          selectedRecipeTitle: selectedRecipeTitle,
          selectedIngredients: selectedIngredients,
          selectedPreparation: selectedPreparation,
          recipeLimit: recipeLimit,
        );
        break;
      default:
        return;
    }

    // Exécution de la navigation avec suppression explicite des animations de transition
    // afin de simuler un remplacement statique de la vue principale.
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),

      // La configuration 'fixed' est requise par l'API Flutter pour forcer
      // le rendu de plus de 3 éléments (ici 6) sans induire de comportement de type 'shifting'.
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.teal,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.teal.shade100,

      // Ajustement dimensionnel de la typographie pour prévenir les débordements (overflows)
      // causés par la densité des 6 onglets sur les écrans à faible résolution.
      selectedFontSize: 10,
      unselectedFontSize: 10,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sick_rounded),
          label: 'Symptômes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_rounded),
          label: 'Catégories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_rounded),
          label: 'Recettes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.kitchen_rounded),
          label: 'Ingrédients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_rounded),
          label: 'Préparation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}
