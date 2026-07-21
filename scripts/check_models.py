import os
from dotenv import load_dotenv
from google import genai

# Chargement de la cle
load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

print("Modeles disponibles :")
for model in client.models.list():
    print(f"- {model.name}")