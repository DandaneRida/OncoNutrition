/// Modèle de données représentant l'utilisateur authentifié (patient).
class User {
  // Identifiant unique de l'utilisateur.
  final int id;

  // Nom complet de l'utilisateur.
  final String nom;

  // Adresse électronique de l'utilisateur, utilisée pour la connexion.
  final String email;

  // Jeton de session (ex: JWT ou simple token) pour les requêtes authentifiées.
  // Déclaré comme nullable car il peut être absent lors de certaines opérations.
  final String? token;

  /// Constructeur principal.
  User({required this.id, required this.nom, required this.email, this.token});

  /// Constructeur de type factory pour instancier un utilisateur à partir des données de l'API.
  /// Permet d'injecter manuellement le jeton d'authentification lors de la connexion.
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      token: token,
    );
  }
}
