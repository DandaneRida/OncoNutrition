import pandas as pd
import os

# 1. Définition du chemin d'accès au fichier source
chemin_entree = os.path.join("backend", "data", "retention_factors.csv")

try:
    df = pd.read_csv(chemin_entree)

    # 2. Nettoyage des données : suppression des en-têtes de catégories internes
    df_propre = df[df['food_before_process'] != df['process']]

    # 3. Configuration du répertoire de destination
    dossier_sortie = "data"
    os.makedirs(dossier_sortie, exist_ok=True)
    chemin_sortie = os.path.join(dossier_sortie, "retention_factors.csv")

    # 4. Sauvegarde des données nettoyées
    df_propre.to_csv(chemin_sortie, index=False, encoding='utf-8')

    print(f"Procédure de nettoyage terminée. Réduction du volume de {len(df)} à {len(df_propre)} enregistrements.")
    print(f"Fichier sauvegardé dans le répertoire cible : {chemin_sortie}")
    
except FileNotFoundError:
    print(f"Erreur : Le fichier {chemin_entree} est introuvable. Veuillez vérifier l'arborescence du projet.")