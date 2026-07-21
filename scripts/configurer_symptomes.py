import pandas as pd
import os

print("Création de la table des profils cliniques NACRe.")
symptomes_data = {
    "id_symptome": [1, 2, 3, 4, 5, 6],
    "nom_symptome": [
        "Nausées, vomissements et dégoûts",
        "Inflammation des muqueuses (Mucosite/Œsophagite)",
        "Diarrhée",
        "Constipation",
        "Dénutrition / Perte de poids sévère",
        "Surcharge pondérale / Risque de prise de poids indésirable"
    ]
}
df_symptomes = pd.DataFrame(symptomes_data)

# Création du répertoire cible et sauvegarde du référentiel
os.makedirs("data", exist_ok=True)
df_symptomes.to_csv("data/symptomes_reference.csv", index=False, encoding='utf-8')

print("Initialisation de la structure des contre-indications dans le fichier des recettes...")
chemin_recettes = "data/recettes_preparees.csv"

if os.path.exists(chemin_recettes):
    df_recettes = pd.read_csv(chemin_recettes)
    df_recettes["symptomes_contre_indiques"] = None
    df_recettes.to_csv(chemin_recettes, index=False, encoding='utf-8')
    print("Mise à jour du référentiel effectuée avec succès.")
else:
    print(f"Erreur d'accès : Le fichier {chemin_recettes} est introuvable.")