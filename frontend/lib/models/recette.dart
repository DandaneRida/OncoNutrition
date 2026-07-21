/// Modèle de données représentant une recette.
/// Contient les informations nutritionnelles et de préparation d'un plat.
class Recette {
  // Identifiant unique de la recette dans la base de données.
  final int id;

  // Titre ou nom de la recette.
  final String titre;

  // Classification principale (ex: Entrée, Plat, Dessert).
  final String categoriePrincipale;

  // Classification secondaire pour affiner les filtres (ex: Végétarien, Sans gluten).
  final String sousCategorie;

  // Temps global estimé pour la réalisation (préparation + cuisson).
  final String tempsTotal;

  // Quantité totale de polyphénols, utilisée pour le tri des recommandations.
  final double totalPolyphenols;

  // Nombre de personnes ou portions prévues pour cette recette.
  final int portions;

  // Chaîne de caractères contenant la liste des ingrédients.
  // Déclarée comme nullable (String?) car elle peut n'être chargée qu'à la demande (ex: pop-up).
  final String? ingredients;

  // Chaîne de caractères contenant les étapes de préparation.
  // Déclarée comme nullable (String?) pour les mêmes raisons d'optimisation.
  final String? preparation;

  /// Constructeur principal requérant les données obligatoires.
  Recette({
    required this.id,
    required this.titre,
    required this.categoriePrincipale,
    required this.sousCategorie,
    required this.tempsTotal,
    required this.totalPolyphenols,
    required this.portions,
    this.ingredients,
    this.preparation,
  });

  /// Constructeur de type factory permettant de créer une instance de [Recette]
  /// à partir d'un dictionnaire JSON renvoyé par l'API backend.
  factory Recette.fromJson(Map<String, dynamic> json) {
    return Recette(
      id: json['id'],
      // Gestion des valeurs nulles avec des valeurs par défaut sécurisées.
      titre: json['titre'] ?? "Recette sans titre",
      categoriePrincipale: json['categorie_principale'] ?? "",
      sousCategorie: json['sous_categorie'] ?? "",
      tempsTotal: json['temps_total']?.toString() ?? "N/A",
      // Conversion sécurisée en double, en gérant les éventuels entiers retournés par l'API.
      totalPolyphenols: (json['total_polyphenols'] as num?)?.toDouble() ?? 0.0,
      // Fallback sur 'nb_personnes' si la clé 'portions' n'est pas présente dans le JSON.
      portions: json['portions'] ?? json['nb_personnes'] ?? 1,
      ingredients: json['ingredients'],
      // Fallback sur 'instructions' si la clé 'preparation' n'est pas présente.
      preparation: json['preparation'] ?? json['instructions'],
    );
  }
}
