import pandas as pd

print("Chargement des fichiers...")
# 1. On charge notre référentiel d'aliments avec les ID
df_foods = pd.read_csv('foods_preparees.csv')

# 2. On charge la grosse table de composition
df_compo = pd.read_excel('composition-data.xlsx', sheet_name='Sheet1')

print("Calcul de la somme des polyphénols pour chaque aliment...")
# 3. On regroupe par aliment et on additionne la colonne 'mean' (qui est en mg/100g ou mg/100ml)
# On s'assure de ne prendre que les lignes où on a une valeur numérique
df_compo['mean'] = pd.to_numeric(df_compo['mean'], errors='coerce').fillna(0)
somme_polyphenols = df_compo.groupby('food')['mean'].sum().reset_index()
somme_polyphenols.rename(columns={'mean': 'total_polyphenols_mg_100g', 'food': 'name'}, inplace=True)

# 4. On fusionne (LEFT JOIN) avec notre fichier foods_preparees
# Attention : il faut que la colonne du nom de l'aliment dans foods.csv corresponde 
colonne_nom_food = 'name' 
df_foods_complet = pd.merge(df_foods, somme_polyphenols, left_on=colonne_nom_food, right_on='name', how='left')

# 5. On remplace les valeurs vides (NaN) par 0 (pour les aliments qui n'ont pas de données de polyphénols)
df_foods_complet['total_polyphenols_mg_100g'] = df_foods_complet['total_polyphenols_mg_100g'].fillna(0)

# 6. Sauvegarde du fichier final
df_foods_complet.to_csv('foods_avec_polyphenols.csv', index=False)

print(f"Terminé ! Le fichier 'foods_avec_polyphenols.csv' a été créé.")
print(df_foods_complet[['id_food', colonne_nom_food, 'total_polyphenols_mg_100g']].head(10))