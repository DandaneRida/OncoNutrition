import pandas as pd
import os

# 1. Construction du chemin absolu et robuste
# Cela pointe vers D:\projet_stage\OncoNutrition\data\recettes_choumicha_complet.csv
dossier_actuel = os.path.dirname(os.path.abspath(__file__))
chemin_csv = os.path.join(dossier_actuel, "..", "data", "recettes_choumicha_complet.csv")

print(f"Tentative de lecture du fichier : {chemin_csv}")

# 2. Charger le fichier actuel
df = pd.read_csv(chemin_csv)

# 3. Remplacer les sauts de ligne (\n ou \r\n) par le séparateur ' | '
df['instructions'] = df['instructions'].astype(str).str.replace(r'\r?\n', ' | ', regex=True)

# 4. Sauvegarder le fichier propre
df.to_csv(chemin_csv, index=False, encoding='utf-8-sig')
print("✨ C'est réparé ! Les étapes sont maintenant séparées par des '|'.")