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

# Extraction des paramètres de configuration de l'environnement de développement.
db_user = os.getenv("DB_USER_DEV")
db_password = os.getenv("DB_PASSWORD_DEV", "")
db_host = os.getenv("DB_HOST_DEV")
db_port = os.getenv("DB_PORT_DEV")
db_name = os.getenv("DB_NAME_DEV")

# Validation de la présence des paramètres requis pour l'initialisation.
if not db_port or not db_user:
    raise ValueError(f"Erreur d'initialisation : Impossible de lire les variables DB_USER_DEV ou DB_PORT_DEV dans {ENV_PATH}.")

print(f"Établissement de la connexion à la base de données : User={db_user}, Host={db_host}:{db_port}, DB={db_name}")

# Génération de l'URI de connexion et instanciation du moteur SQLAlchemy.
DATABASE_URI = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
engine = create_engine(DATABASE_URI)

# ---------------------------------------------------------
# 2. Configuration des chemins d'accès aux fichiers
# ---------------------------------------------------------
DATA_DIR = os.path.join(BASE_DIR, "data")

FILE_FOODS = os.path.join(DATA_DIR, "foods_preparees_complet.csv")
FILE_RECETTES = os.path.join(DATA_DIR, "recettes_analysees_ia_v4.csv")
FILE_RECETTES_ING = os.path.join(DATA_DIR, "recette_ingredients_final.csv")
FILE_SYMPTOMES = os.path.join(DATA_DIR, "symptomes_reference.csv")

# ---------------------------------------------------------
# 3. Chargement des ensembles de données (DataFrames)
# ---------------------------------------------------------
print("Lecture des fichiers CSV depuis le répertoire source :", DATA_DIR)
df_foods = pd.read_csv(FILE_FOODS)
df_recettes = pd.read_csv(FILE_RECETTES)
df_recette_ing = pd.read_csv(FILE_RECETTES_ING)
df_symptomes = pd.read_csv(FILE_SYMPTOMES)

# ---------------------------------------------------------
# 4. Traitement et persistance : Table SYMPTOMES
# ---------------------------------------------------------
print("Insertion des enregistrements dans la table 'symptomes'...")
# Renommage des colonnes pour assurer la conformité avec le schéma de la base de données cible.
df_symp_pg = df_symptomes[['id_symptome', 'nom_symptome']].rename(columns={
    'nom_symptome': 'libelle_symptome'
})
df_symp_pg.to_sql('symptomes', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 5. Traitement et persistance : Table INGREDIENTS
# ---------------------------------------------------------
print("Insertion des enregistrements dans la table 'ingredients'...")
df_ing_pg = df_foods[['id_food', 'food_source_french', 'total_polyphenols_mg_100g']].rename(columns={
    'id_food': 'id',
    'food_source_french': 'nom',
    'total_polyphenols_mg_100g': 'teneur_polyphenols_mg_100g'
})
# Nettoyage des données : suppression des valeurs nulles et déduplication basées sur la clé nominale.
df_ing_pg = df_ing_pg.dropna(subset=['nom']).drop_duplicates(subset=['nom'])
df_ing_pg.to_sql('ingredients', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 6. Traitement et persistance : Table RECETTES
# ---------------------------------------------------------
print("Insertion des enregistrements dans la table 'recettes'...")
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
# 7. Traitement et persistance : Table RECETTE_INGREDIENTS (Jointure)
# ---------------------------------------------------------
print("Insertion des enregistrements dans la table de liaison 'recette_ingredients'...")
df_ri_pg = df_recette_ing[['id_recette', 'id_food', 'quantite_g', 'facteur_retention']].rename(columns={
    'id_recette': 'recette_id',
    'id_food': 'ingredient_id',
    'quantite_g': 'quantite_grammes'
})
df_ri_pg.to_sql('recette_ingredients', engine, if_exists='append', index=False)

# ---------------------------------------------------------
# 8. Traitement et persistance : Table RECETTE_SYMPTOMES (Jointure)
# ---------------------------------------------------------
print("Calcul et insertion des enregistrements dans la table de liaison 'recette_symptomes'...")
liaisons_symptomes = []

# Itération sur l'ensemble des recettes pour extraire et normaliser les contre-indications cliniques.
for idx, row in df_recettes.iterrows():
    if pd.notna(row['symptomes_contre_indiques']):
        symptomes_ids = str(row['symptomes_contre_indiques']).split('|')
        for s_id in symptomes_ids:
            liaisons_symptomes.append({
                'id_recette': row['id_recette'],
                'id_symptome': int(s_id)
            })

df_rec_symp_pg = pd.DataFrame(liaisons_symptomes)

# Insertion des relations après déduplication.
if not df_rec_symp_pg.empty:
    df_rec_symp_pg = df_rec_symp_pg.drop_duplicates()
    df_rec_symp_pg.to_sql('recette_symptomes', engine, if_exists='append', index=False)

print("Procédure de migration vers PostgreSQL terminée avec succès.")