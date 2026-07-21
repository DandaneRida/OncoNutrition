import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

/// Point d'entrée d'exécution de l'application Flutter.
void main() {
  runApp(const OncoNutritionApp());
}

/// Classe racine du cycle de vie de l'application.
/// Assure l'initialisation du contexte global, l'application de la charte graphique
/// et la définition du routage initial.
class OncoNutritionApp extends StatelessWidget {
  const OncoNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OncoNutrition',
      // Désactivation de l'indicateur de mode débogage de l'interface utilisateur.
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Génération dynamique de la palette de couleurs globale basée sur la teinte principale (Teal).
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Instanciation du module d'authentification comme point de démarrage par défaut du flux utilisateur.
      home: const LoginScreen(),
    );
  }
}
