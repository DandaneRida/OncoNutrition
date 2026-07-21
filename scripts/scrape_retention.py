import pandas as pd
import time
import os
import requests

def main():
    all_tables = []
    print("Démarrage de la procédure d'extraction des données sur Phenol-Explorer...")

    # Paramétrage de la pagination (13 pages prévues pour 316 éléments)
    for page in range(1, 14):
        url = f"http://phenol-explorer.eu/food-processing/foods?page={page}"
        print(f"Traitement de la page {page}/13...")
        
        try:
            # Injection de l'en-tête User-Agent pour conformité de la requête HTTP
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
            response = requests.get(url, headers=headers)
            
            # Extraction automatique des structures tabulaires HTML
            tables = pd.read_html(response.text)
            
            if tables:
                df_page = tables[0]
                all_tables.append(df_page)
                
        except Exception as e:
            print(f"Erreur d'extraction sur la page {page} : {e}")
            
        # Temporisation requise pour prévenir la surcharge du serveur cible
        time.sleep(1.5)

    # Consolidation des données extraites
    df_final = pd.concat(all_tables, ignore_index=True)

    # Nettoyage structurel : suppression de la colonne fonctionnelle finale
    if len(df_final.columns) == 7:
        df_final = df_final.iloc[:, :-1]

    # Normalisation de la nomenclature des colonnes pour intégration en base de données
    df_final.columns = [
        'food_before_process', 
        'food_after_process', 
        'process', 
        'yield_factor', 
        'num_compounds', 
        'num_data'
    ]

    # Création de l'arborescence et sauvegarde
    dossier_data = 'data'
    os.makedirs(dossier_data, exist_ok=True)
    chemin_csv = os.path.join(dossier_data, 'retention_factors.csv')
    df_final.to_csv(chemin_csv, index=False, encoding='utf-8')
    
    print("-" * 50)
    print("Procédure d'extraction terminée.")
    print(f"{len(df_final)} procédés culinaires ont été indexés dans : {chemin_csv}")

if __name__ == "__main__":
    main()