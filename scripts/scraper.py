import os
import time
import re
import requests
from bs4 import BeautifulSoup
import pandas as pd

# ==============================================================================
# 1. LOGIQUE D'EXTRACTION UNITAIRE D'UNE RECETTE
# ==============================================================================
def scraper_recette_choumicha(url):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    }
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
    except Exception:
        return None

    soup = BeautifulSoup(response.content, 'html.parser')
    
    # Extraction du titre
    titre_tag = soup.find('h1', itemprop="name") or soup.find('h1')
    titre = titre_tag.text.strip() if titre_tag else "Titre introuvable"

    # Traitement de la catégorisation via le fil d'Ariane
    categorie_principale = "Saveurs du Maroc"
    sous_categorie = "Non défini"
    mots_parasites = ["accueil", "recettes", "imprimer", "partager", "commenter", "vidéos", "imprime"]
    
    breadcrumb = soup.find('div', class_='breadcrumb') or soup.find(id='path')
    if breadcrumb:
        liens = [a.text.strip() for a in breadcrumb.find_all('a') if a.text.strip()]
        categories_propres = [c for c in liens if c.lower() not in mots_parasites]
        if len(categories_propres) == 1:
            sous_categorie = categories_propres[0]
        elif len(categories_propres) >= 2:
            categorie_principale = categories_propres[0]
            sous_categorie = categories_propres[1]

    # Normalisation sémantique des catégories pour le domaine OncoNutrition
    valeurs_invalides = ["non défini", "non definis", "autres", "recettes"]
    if sous_categorie.lower() in valeurs_invalides or not sous_categorie.strip():
        texte_analyse = (titre + " " + url).lower()
        if any(m in texte_analyse for m in ["jus", "boisson", "smoothie"]): sous_categorie = "Jus et Boissons"
        elif any(m in texte_analyse for m in ["soupe", "harira", "veloute"]): sous_categorie = "Soupes et Hariras"
        elif "tajine" in texte_analyse: sous_categorie = "Tajines"
        elif any(m in texte_analyse for m in ["poisson", "mer", "crevette", "paella"]): sous_categorie = "Poissons et Crustacés"
        elif any(m in texte_analyse for m in ["poulet", "dinde", "volaille"]): sous_categorie = "Volailles"
        elif any(m in texte_analyse for m in ["viande", "agneau", "veau", "boeuf"]): sous_categorie = "Plats de Viandes"
        elif "salade" in texte_analyse: sous_categorie = "Salades"
        elif any(m in texte_analyse for m in ["biscuit", "gateau", "crème", "sucre"]): sous_categorie = "Desserts et Pâtisseries"
        elif any(m in texte_analyse for m in ["pain", "batbot", "harcha", "pizza"]): sous_categorie = "Pains et Boulangerie"
        else: sous_categorie = "Plats Principaux"

    if categorie_principale.lower() in valeurs_invalides:
        categorie_principale = "Saveurs du Maroc"

    # Extraction des métriques temporelles
    temps_cuisson = "Non spécifié"
    tag_cuisson = soup.find(itemprop="cookTime")
    if tag_cuisson:
        temps_cuisson = tag_cuisson.text.strip()

    temps_total = "Non spécifié"
    tag_total = soup.find(itemprop="totalTime")
    if tag_total:
        temps_total = tag_total.text.strip()

    # Extraction des portions
    nombre_personnes = 1  
    tag_personnes = soup.find(itemprop="recipeYield")
    if tag_personnes:
        chiffres = re.findall(r'\d+', tag_personnes.text)
        if chiffres:
            nombre_personnes = int(chiffres[0])
    else:
        info_block = soup.find('ul', class_="recipe-info")
        if info_block:
            match = re.search(r'(?:pour\s*)?(\d+)\s*(?:personnes|portions|parts|pers)', info_block.text.lower())
            if match:
                nombre_personnes = int(match.group(1))

    # Agrégation des ingrédients
    ingredients_list = []
    ing_tags = soup.find_all(itemprop="recipeIngredient")
    if ing_tags:
        ingredients_list = [ing.text.strip() for ing in ing_tags]
    else:
        prep_block = soup.find(class_="preparation")
        if prep_block and prep_block.find_parent():
            for ul in prep_block.find_parent().find_all('ul'):
                if 'recipe-info' not in ul.get('class', []):
                    ingredients_list = [li.text.strip() for li in ul.find_all('li')]
                    break

    # Formatage de la section instructions avec préservation des sauts de ligne
    instructions = ""
    instructions_section = soup.find(itemprop="recipeInstructions") or soup.find(class_="preparation")
    if instructions_section:
        texte_avec_separateur = instructions_section.get_text(separator="\n")
        lignes_nettoyees = [line.strip() for line in texte_avec_separateur.splitlines() if line.strip()]
        instructions = "\n".join(lignes_nettoyees)

    return {
        "url": url,
        "titre": titre,
        "categorie_principale": categorie_principale.capitalize(),
        "sous_categorie": sous_categorie.capitalize(),
        "temps_cuisson": temps_cuisson,
        "temps_total": temps_total,
        "nombre_personnes": nombre_personnes,
        "ingredients": " | ".join(ingredients_list),
        "instructions": instructions
    }

# ==============================================================================
# 2. LOGIQUE DE NAVIGATION DE L'ANNUAIRE
# ==============================================================================
def recuperer_urls_recettes(url_liste):
    headers = {"User-Agent": "Mozilla/5.0"}
    urls_recettes = []
    try:
        response = requests.get(url_liste, headers=headers, timeout=10)
        soup = BeautifulSoup(response.content, 'html.parser')
        for a in soup.find_all('a', href=True):
            href = a['href']
            if '/recette/' in href and href.endswith('.html'):
                full_url = f"https://www.choumicha.ma{href}" if href.startswith('/') else href
                if full_url not in urls_recettes:
                    urls_recettes.append(full_url)
    except Exception:
        pass
    return urls_recettes

# ==============================================================================
# 3. EXÉCUTION DU PIPELINE
# ==============================================================================
if __name__ == "__main__":
    liste_urls_totale = []
    
    print("Étape 1 : Indexation des liens de recettes (Pages 1 à 62)...")
    
    # Paramétrage de la boucle d'exploration
    for num_page in range(1, 63): 
        url_pagination = "https://www.choumicha.ma/accueil-recettes.html" if num_page == 1 else f"https://www.choumicha.ma/accueil-recettes/Page-{num_page}.html"
        print(f"   Extraction en cours de la page {num_page}/62 : {url_pagination}")
        urls_page = recuperer_urls_recettes(url_pagination)
        for u in urls_page:
            if u not in liste_urls_totale:
                liste_urls_totale.append(u)
        time.sleep(0.3)
        
    print(f"\nÉtape 1 terminée. {len(liste_urls_totale)} URLs uniques répertoriées.")
    print("Étape 2 : Extraction séquentielle des métadonnées de recettes...")
    
    toutes_les_recettes = []
    for i, url in enumerate(liste_urls_totale, 1):
        print(f"   [{i}/{len(liste_urls_totale)}] Traitement : {url}")
        donnees = scraper_recette_choumicha(url)
        if donnees:
            toutes_les_recettes.append(donnees)
        time.sleep(1) # Temporisation réseau
            
    if toutes_les_recettes:
        df = pd.DataFrame(toutes_les_recettes)
        dossier_data = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
        os.makedirs(dossier_data, exist_ok=True)
        
        chemin_csv = os.path.join(dossier_data, "recettes_choumicha_complet.csv")
        df.to_csv(chemin_csv, index=False, encoding='utf-8-sig')
        
        print(f"\nProcédure terminée. Export des données sauvegardé : {chemin_csv}")