import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

# ---------------------------------------------------------
# 1. Chargement des variables d'environnement
# ---------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, ".env")
load_dotenv(dotenv_path=ENV_PATH)

# Utilisation des variables de votre fichier .env de developpement
db_user = os.getenv("DB_USER_DEV")
db_password = os.getenv("DB_PASSWORD_DEV", "")
db_host = os.getenv("DB_HOST_DEV")
db_port = os.getenv("DB_PORT_DEV")
db_name = os.getenv("DB_NAME_DEV")

if not db_port or not db_user:
    raise ValueError(f"Erreur : Impossible de lire les variables DB_USER_DEV ou DB_PORT_DEV dans {ENV_PATH}.")

print(f"Connexion a la base de donnees : User={db_user}, Host={db_host}:{db_port}, DB={db_name}")

# Construction de la chaine de connexion pour SQLAlchemy
DATABASE_URI = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
engine = create_engine(DATABASE_URI)

# ---------------------------------------------------------
# 2. Configuration des chemins des fichiers
# ---------------------------------------------------------
DATA_DIR = os.path.join(BASE_DIR, "data")

FILE_FOODS = os.path.join(DATA_DIR, "foods_preparees_complet.csv")
FILE_RECETTES = os.path.join(DATA_DIR, "recettes_analysees_ia_v4.csv")
FILE_RECETTES_ING = os.path.join(DATA_DIR, "recette_ingredients_final.csv")
FILE_SYMPTOMES = os.path.join(DATA_DIR, "symptomes_reference.csv")

# ---------------------------------------------------------
# 3. Chargement des DataFrames
# ---------------------------------------------------------
print("Chargement des fichiers CSV depuis le repertoire :", DATA_DIR)
df_foods = pd.read_csv(FILE_FOODS)
df_recettes = pd.read_csv(FILE_RECETTES)
df_recette_ing = pd.read_csv(FILE_RECETTES_ING)
df_symptomes = pd.read_csv(FILE_SYMPTOMES)

# ---------------------------------------------------------
# 4. Traitement et Insertion : SYMPTOMES
# ---------------------------------------------------------
print("Insertion des donnees dans la table 'symptomes'...")
# CORRECTION ICI : Utilisation de 'id_symptome' et 'nom_symptome'
df_symp_pg = df_symptomes[['id_symptome', 'nom_symptome']].rename(columns={
    'nom_symptome': 'libelle_symptome'
})
df_symp_pg.to_sql('symptomes', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 5. Traitement et Insertion : INGREDIENTS
# ---------------------------------------------------------
print("Insertion des donnees dans la table 'ingredients'...")
df_ing_pg = df_foods[['id_food', 'food_source_french', 'total_polyphenols_mg_100g']].rename(columns={
    'id_food': 'id',
    'food_source_french': 'nom',
    'total_polyphenols_mg_100g': 'teneur_polyphenols_mg_100g'
})
df_ing_pg = df_ing_pg.dropna(subset=['nom']).drop_duplicates(subset=['nom'])
df_ing_pg.to_sql('ingredients', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 6. Traitement et Insertion : RECETTES
# ---------------------------------------------------------
print("Insertion des donnees dans la table 'recettes'...")
df_rec_pg = df_recettes[[
    'id_recette', 'titre', 'categorie_principale', 'sous_categorie', 
    'temps_cuisson', 'temps_total', 'nombre_personnes', 'instructions', 
    'url', 'teneur_en_polyphenols', 'est_laitier', 'ingredients'
]].rename(columns={
    'id_recette': 'id',
    'teneur_en_polyphenols': 'total_polyphenols'
})
df_rec_pg.to_sql('recettes', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 7. Traitement et Insertion : RECETTE_INGREDIENTS
# ---------------------------------------------------------
print("Insertion des donnees dans la table 'recette_ingredients'...")
df_ri_pg = df_recette_ing[['id_recette', 'id_food', 'quantite_g', 'facteur_retention']].rename(columns={
    'id_recette': 'recette_id',
    'id_food': 'ingredient_id',
    'quantite_g': 'quantite_grammes'
})
df_ri_pg.to_sql('recette_ingredients', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 8. Traitement et Insertion : RECETTE_SYMPTOMES
# ---------------------------------------------------------
print("Insertion des donnees dans la table 'recette_symptomes'...")
liaisons_symptomes = []

for idx, row in df_recettes.iterrows():
    if pd.notna(row['symptomes_contre_indiques']):
        symptomes_ids = str(row['symptomes_contre_indiques']).split('|')
        for s_id in symptomes_ids:
            liaisons_symptomes.append({
                'id_recette': row['id_recette'],
                'id_symptome': int(s_id)
            })

df_rec_symp_pg = pd.DataFrame(liaisons_symptomes)

if not df_rec_symp_pg.empty:
    df_rec_symp_pg = df_rec_symp_pg.drop_duplicates()
    df_rec_symp_pg.to_sql('recette_symptomes', engine, if_exists='append', index=False)

print("Migration vers PostgreSQL terminee avec succes !")