
#!/usr/bin/env bash
set -euo pipefail

# Dossier du projet (adapter si besoin)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_DIR"

# ⚠️ À ADAPTER / METTRE DANS TON ENV (ou un .env)
export SUPABASE_URL='https://bcuxfuqgwoqyammgmpjw.supabase.co'
export SUPABASE_SERVICE_ROLE_KEY='sb_secret_GnRXdBMwhJqpO4LZGKfwKg_HbVpIYjh'


export FIREBASE_SERVICE_ACCOUNT="$PROJECT_DIR/scripts/serviceAccountKey.json"

if [ ! -f "$FIREBASE_SERVICE_ACCOUNT" ]; then
  echo "❌ Fichier serviceAccountKey.json introuvable: $FIREBASE_SERVICE_ACCOUNT"
  exit 1
fi

# Installer les dépendances si besoin
if [ ! -d "node_modules" ]; then
  echo "📦 Installation des dépendances..."
  npm install firebase-admin @supabase/supabase-js node-fetch@3
fi

echo "🚀 Lancement du script Node pour compléter les images..."
node scripts/add_missing_place_images.js
