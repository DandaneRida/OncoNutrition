from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel, EmailStr
import os
from typing import List
import bcrypt

# Configuration de la base de données via les variables d'environnement
DATABASE_URL = f"postgresql://{os.getenv('DB_USER_DEV')}:{os.getenv('DB_PASSWORD_DEV')}@{os.getenv('DB_HOST_DEV')}:{os.getenv('DB_PORT_DEV')}/{os.getenv('DB_NAME_DEV')}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

app = FastAPI(title="OncoNutrition API", version="2.0")

# Activation de CORS pour permettre à Flutter de se connecter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simulation de décodage JWT ultra-simplifié pour le projet
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    # Pour faire simple sans config complexe de JWT, le token est l'email de l'utilisateur
    query = text("SELECT id, nom, email FROM utilisateurs WHERE email = :email;")
    user = db.execute(query, {"email": token}).mappings().first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Utilisateur introuvable")
    return user

# --- SCHEMAS DE DONNÉES (Pydantic) ---
class UserSignup(BaseModel):
    nom: str
    email: EmailStr
    password: str

class SymptomUpdate(BaseModel):
    symptome_ids: List[int]

# --- ROUTES AUTHENTIFICATION ---

@app.post("/signup", status_code=201)
def signup(user: UserSignup, db: Session = Depends(get_db)):
    try:
        # 1. On transforme le mot de passe en "bytes" puis on le hache avec bcrypt
        password_bytes = user.password.encode('utf-8')
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(password_bytes, salt).decode('utf-8')

        # 2. On insère le mot de passe haché dans la colonne 'mot_de_passe_hash'
        query = text("""
            INSERT INTO utilisateurs (nom, email, mot_de_passe_hash) 
            VALUES (:nom, :email, :password) 
            RETURNING id, nom, email;
        """)
        
        result = db.execute(query, {
            "nom": user.nom, 
            "email": user.email, 
            "password": hashed_password  # On envoie la version hachée sécurisée !
        })
        db.commit()
        return result.mappings().first()
        
    except Exception as e:
        db.rollback()
        print(f"\n---  ERREUR INSCRIPTION : {e}\n")
        raise HTTPException(
            status_code=400, 
            detail="Une erreur est survenue lors de l'inscription."
        )

@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # 1. On cherche l'utilisateur avec la bonne colonne de mot de passe haché
    query = text("SELECT email, mot_de_passe_hash FROM utilisateurs WHERE email = :email;")
    user = db.execute(query, {"email": form_data.username}).mappings().first()
    
    # 2. Si l'email n'existe pas dans la base
    if not user:
        raise HTTPException(status_code=400, detail="Email ou mot de passe incorrect.")
        
    # 3. On vérifie le mot de passe avec bcrypt
    password_correct = bcrypt.checkpw(
        form_data.password.encode('utf-8'),
        user["mot_de_passe_hash"].encode('utf-8')
    )
    
    # Si le mot de passe est faux
    if not password_correct:
        raise HTTPException(status_code=400, detail="Email ou mot de passe incorrect.")
        
    # 4. Si tout est bon, on renvoie ton système de Token simplifié (l'email) !
    return {"access_token": user["email"], "token_type": "bearer"}

# --- ROUTES SYMPTÔMES ---

@app.get("/symptomes")
def get_all_symptomes(db: Session = Depends(get_db)):
    return db.execute(text("SELECT id_symptome, libelle_symptome FROM symptomes;")).mappings().all()

@app.get("/profil/symptomes")
def get_user_symptomes(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    query = text("""
        SELECT s.id_symptome, s.libelle_symptome 
        FROM symptomes s
        JOIN utilisateur_symptome us ON s.id_symptome = us.id_symptome
        WHERE us.id_utilisateur = :u_id;
    """)
    return db.execute(query, {"u_id": current_user["id"]}).mappings().all()

@app.post("/profil/symptomes")
def update_user_symptomes(data: SymptomUpdate, current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        # On vide les anciens symptômes enregistrés
        db.execute(text("DELETE FROM utilisateur_symptome WHERE id_utilisateur = :u_id;"), {"u_id": current_user["id"]})
        # On insère les nouveaux
        for s_id in data.symptome_ids:
            db.execute(text("INSERT INTO utilisateur_symptome (id_utilisateur, id_symptome) VALUES (:u_id, :s_id);"), {"u_id": current_user["id"], "s_id": s_id})
        db.commit()
        return {"message": "Symptômes mis à jour"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

# --- ROUTES RECETTES (FILTRES ET RECOMMANDATIONS) ---

@app.get("/recettes/sous-categories")
def get_sous_categories(db: Session = Depends(get_db)):
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
    # 1. Sécurité pour la limite n (entre 1 et 10)
    if limite < 1 or limite > 10:
        limite = 5

    # Base de la requête SQL (sans le filtre de catégorie pour l'instant)
    # Elle exclut toujours les recettes incompatibles avec les symptômes du patient
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
    
    # Paramètres de base pour la requête SQL
    params = {
        "u_id": current_user["id"], 
        "limite": limite
    }

    # 2. Traitement à part pour "Toutes les catégories"
    # On définit les mots-clés qui signifient "Pas de filtre" (on gère les majuscules/minuscules et les accents)
    pass_filter_keywords = ["toutes les catégories", "toutes les categories", "toutes", "all", ""]

    # On applique le filtre de sous-catégorie UNIQUEMENT si l'utilisateur a choisi une vraie catégorie spécifique
    if sous_categorie and sous_categorie.strip().lower() not in pass_filter_keywords:
        sql_query += " AND r.sous_categorie = :sous_cat"
        params["sous_cat"] = sous_categorie

    # 3 & 4. Tri décroissant par polyphénols et application de la limite n
    sql_query += """
        ORDER BY r.total_polyphenols DESC 
        LIMIT :limite;
    """
    
    try:
        result = db.execute(text(sql_query), params).mappings().all()
        return result
    except Exception as e:
        db.rollback()
        print(f"\n---  ERREUR RECETTES RECOMMANDÉES : {e}\n")
        raise HTTPException(
            status_code=500, 
            detail=f"Erreur lors de la récupération des recettes : {str(e)}"
        )