/// Modèle de données représentant un symptôme médical ou un effet secondaire.
/// Utilisé pour filtrer les recettes selon les contre-indications du patient.
class Symptome {
  // Identifiant unique du symptôme dans la base de données.
  final int idSymptome;

  // Nom ou description textuelle du symptôme (ex: "Nausées", "Mucite").
  final String libelleSymptome;

  /// Constructeur principal.
  Symptome({required this.idSymptome, required this.libelleSymptome});

  /// Constructeur de type factory pour la désérialisation.
  /// Convertit le dictionnaire JSON de l'API en une instance objet de [Symptome].
  factory Symptome.fromJson(Map<String, dynamic> json) {
    return Symptome(
      idSymptome: json['id_symptome'],
      libelleSymptome: json['libelle_symptome'],
    );
  }
}
