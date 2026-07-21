# ==========================================
# IMPORTATIONS DES BIBLIOTHÈQUES NÉCESSAIRES
# ==========================================
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel, EmailStr, field_validator
import os
import re
from typing import List
import bcrypt

# ==========================================
# CONFIGURATION DE LA BASE DE DONNÉES
# ==========================================
# Récupération de l'URL de connexion
# Priorité à la variable DATABASE_URL complète (utilisée par Vercel et Supabase en production)
DATABASE_URL = os.getenv("DATABASE_URL")

# Si DATABASE_URL n'existe pas, on utilise la logique locale de développement
if not DATABASE_URL:
    DATABASE_URL = f"postgresql://{os.getenv('DB_USER_DEV')}:{os.getenv('DB_PASSWORD_DEV')}@{os.getenv('DB_HOST_DEV')}:{os.getenv('DB_PORT_DEV')}/{os.getenv('DB_NAME_DEV')}"

# Initialisation du moteur SQLAlchemy pour communiquer avec PostgreSQL
# Le paramètre pool_pre_ping=True est recommandé pour les environnements Serverless comme Vercel
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Création d'une usine à sessions pour gérer les transactions avec la base de données
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# ==========================================
# INITIALISATION DE L'APPLICATION FASTAPI
# ==========================================
app = FastAPI(title="OncoNutrition API", version="1.0")

# Ajout du Middleware CORS : Indispensable pour autoriser l'application Flutter (frontend) 
# à communiquer avec ce serveur (backend) sans être bloquée par la politique de sécurité du navigateur.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Autorise toutes les origines (à restreindre en production)
    allow_credentials=True,
    allow_methods=["*"], # Autorise toutes les méthodes HTTP (GET, POST, etc.)
    allow_headers=["*"],
)

# Configuration simplifiée de l'authentification (utilise l'email comme token pour ce projet)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# ==========================================
# DÉPENDANCES (DEPENDENCY INJECTION)
# ==========================================

def get_db():
    """Ouvre une session de base de données pour une requête et la ferme automatiquement à la fin."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """Vérifie l'identité de l'utilisateur à partir du token (ici, l'email) passé dans la requête."""
    query = text("SELECT id, nom, email FROM utilisateurs WHERE email = :email;")
    user = db.execute(query, {"email": token}).mappings().first()
    
    # Si l'utilisateur n'existe pas, on bloque l'accès
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Utilisateur introuvable")
    return user

# ==========================================
# MODÈLES DE DONNÉES (PYDANTIC SCHEMAS)
# ==========================================
# Ces classes définissent la structure des données attendues dans le corps des requêtes (Body)

class UserSignup(BaseModel):
    nom: str
    email: EmailStr
    password: str

    @field_validator('password')
    @classmethod
    def validate_password(cls, value: str) -> str:
        """
        Valide la complexité du mot de passe.
        Critères : > 8 caractères, au moins 1 majuscule, au moins 1 chiffre.
        """
        pattern = r'^(?=.*[A-Z])(?=.*\d).{9,}$'
        if not re.match(pattern, value):
            raise ValueError(
                "Le mot de passe doit contenir strictement plus de 8 caractères, "
                "incluant au moins une lettre majuscule et un chiffre."
            )
        return value

class SymptomUpdate(BaseModel):
    symptome_ids: List[int]

# ==========================================
# ROUTES D'AUTHENTIFICATION
# ==========================================

@app.post("/signup", status_code=201)
def signup(user: UserSignup, db: Session = Depends(get_db)):
    """Crée un nouveau compte utilisateur en hachant son mot de passe."""
    try:
        # Sécurisation du mot de passe avec l'algorithme bcrypt
        password_bytes = user.password.encode('utf-8')
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')

        # Insertion dans la base de données
        query = text("""
            INSERT INTO utilisateurs (nom, email, mot_de_passe_hash) 
            VALUES (:nom, :email, :password) 
            RETURNING id, nom, email;
        """)
        
        result = db.execute(query, {
            "nom": user.nom, 
            "email": user.email, 
            "password": hashed_password 
        })
        db.commit() # Validation de la transaction
        return result.mappings().first()
        
    except Exception as e:
        db.rollback() # Annulation en cas d'erreur
        print(f"\n--- ERREUR INSCRIPTION : {e}\n")
        raise HTTPException(status_code=400, detail="Une erreur est survenue lors de l'inscription.")

@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Vérifie les identifiants et connecte l'utilisateur."""
    # Recherche de l'utilisateur par son email
    query = text("SELECT email, mot_de_passe_hash FROM utilisateurs WHERE email = :email;")
    user = db.execute(query, {"email": form_data.username}).mappings().first()
    
    if not user:
        raise HTTPException(status_code=400, detail="Email ou mot de passe incorrect.")
        
    # Vérification de la correspondance du mot de passe haché
    password_correct = bcrypt.checkpw(
        form_data.password.encode('utf-8'),
        user["mot_de_passe_hash"].encode('utf-8')
    )
    
    if not password_correct:
        raise HTTPException(status_code=400, detail="Email ou mot de passe incorrect.")
        
    # Renvoie l'email en guise de token d'accès simplifié
    return {"access_token": user["email"], "token_type": "bearer"}

# ==========================================
# ROUTES DU PROFIL PATIENT
# ==========================================

@app.get("/profil/me")
def get_user_profile(current_user: dict = Depends(get_current_user)):
    """Renvoie les informations de base de l'utilisateur connecté."""
    # Les données sont déjà validées et récupérées par 'get_current_user'
    return {
        "nom": current_user["nom"],
        "email": current_user["email"]
    }

# ==========================================
# ROUTES DES SYMPTÔMES
# ==========================================

@app.get("/symptomes")
def get_all_symptomes(db: Session = Depends(get_db)):
    """Récupère la liste complète des symptômes de référence depuis la base."""
    return db.execute(text("SELECT id_symptome, libelle_symptome FROM symptomes;")).mappings().all()

@app.get("/profil/symptomes")
def get_user_symptomes(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    """Récupère uniquement les symptômes actuellement enregistrés par l'utilisateur."""
    query = text("""
        SELECT s.id_symptome, s.libelle_symptome 
        FROM symptomes s
        JOIN utilisateur_symptome us ON s.id_symptome = us.id_symptome
        WHERE us.id_utilisateur = :u_id;
    """)
    return db.execute(query, {"u_id": current_user["id"]}).mappings().all()

@app.post("/profil/symptomes")
def update_user_symptomes(data: SymptomUpdate, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    """Met à jour les symptômes de l'utilisateur (remplace les anciens par la nouvelle sélection)."""
    try:
        # 1. Suppression des anciens symptômes
        db.execute(text("DELETE FROM utilisateur_symptome WHERE id_utilisateur = :u_id;"), {"u_id": current_user["id"]})
        
        # 2. Insertion des nouveaux symptômes sélectionnés
        for s_id in data.symptome_ids:
            db.execute(text("INSERT INTO utilisateur_symptome (id_utilisateur, id_symptome) VALUES (:u_id, :s_id);"), {"u_id": current_user["id"], "s_id": s_id})
        
        db.commit()
        return {"message": "Symptômes mis à jour"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# ROUTES DES RECETTES ET RECOMMANDATIONS
# ==========================================

@app.get("/recettes/sous-categories")
def get_sous_categories(db: Session = Depends(get_db)):
    """Récupère la liste des sous-catégories de recettes uniques pour les filtres."""
    query = text("SELECT DISTINCT sous_categorie FROM recettes WHERE sous_categorie IS NOT NULL ORDER BY sous_categorie ASC;")
    result = db.execute(query).fetchall()
    return [row[0] for row in result]

@app.get("/profil/recettes-recommandees")
def get_recommended_recipes(
    sous_categorie: str = None,
    limite: int = 5,
    current_user: dict = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """
    Génère des recommandations de recettes personnalisées.
    Exclut automatiquement les recettes contenant des ingrédients déconseillés selon les symptômes de l'utilisateur.
    """
    # 1. Validation de la limite de résultats (entre 1 et 10)
    if limite < 1 or limite > 10:
        limite = 5

    # 2. Requête SQL de base : Sélectionne les recettes compatibles
    # La sous-requête (NOT EXISTS) permet d'exclure les recettes liées à un symptôme de l'utilisateur
    sql_query = """
        SELECT r.id, r.titre, r.categorie_principale, r.sous_categorie, 
               r.temps_total, r.temps_cuisson, r.total_polyphenols, 
               r.nombre_personnes AS portions, r.ingredients, r.instructions AS preparation
        FROM recettes r 
        WHERE NOT EXISTS (
            SELECT 1 
            FROM recette_symptomes rs
            INNER JOIN utilisateur_symptome us ON rs.id_symptome = us.id_symptome
            WHERE rs.id_recette = r.id 
              AND us.id_utilisateur = :u_id
        )
    """
    
    params = {"u_id": current_user["id"], "limite": limite}

    # 3. Mots-clés pour ignorer le filtre de catégorie
    pass_filter_keywords = ["toutes les catégories", "toutes les categories", "toutes", "all", ""]

    # 4. Ajout dynamique du filtre de catégorie si nécessaire
    if sous_categorie and sous_categorie.strip().lower() not in pass_filter_keywords:
        sql_query += " AND r.sous_categorie = :sous_cat"
        params["sous_cat"] = sous_categorie

    # 5. Tri des résultats par richesse en polyphénols et application de la limite
    sql_query += """
        ORDER BY r.total_polyphenols DESC 
        LIMIT :limite;
    """
    
    try:
        result = db.execute(text(sql_query), params).mappings().all()
        return result
    except Exception as e:
        db.rollback()
        print(f"\n--- ERREUR RECETTES RECOMMANDÉES : {e}\n")
        raise HTTPException(
            status_code=500, 
            detail=f"Erreur lors de la récupération des recettes : {str(e)}"
        )