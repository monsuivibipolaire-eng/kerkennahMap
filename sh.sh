#!/bin/bash

# === CONFIGURATION ===
# Mets "true" si tu veux supprimer les .spec.ts
DELETE_SPECS=false

echo "Nettoyage des fichiers inutiles..."


echo "Suppression des fichiers *.bak.* ..."
find ./src -type f -name "*.bak.*" -print -delete

echo "Suppression des fichiers *.backup.* ..."
find ./src -type f -name "*.backup.*" -print -delete

echo "Suppression des fichiers temporaires *~ ..."
find ./src -type f -name "*~" -print -delete

echo "Suppression des fichiers swap (.swp / .swo) ..."
find ./src -type f \( -name "*.swp" -o -name "*.swo" \) -print -delete

if [ "$DELETE_SPECS" = true ]; then
  echo "Suppression des fichiers .spec.ts ..."
  find ./src -type f -name "*.spec.ts" -print -delete
else
  echo "Les fichiers .spec.ts ne seront PAS supprimés."
fi

echo "Nettoyage terminé."
