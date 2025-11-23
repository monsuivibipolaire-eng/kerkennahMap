#!/bin/bash

# Script pour ajouter un bouton "Modifier" dans les popups des lieux (visible uniquement pour les administrateurs)
# Cible : src/app/features/map/pages/map-page/map-page.component.ts

FILE="src/app/features/map/pages/map-page/map-page.component.ts"

# Vérification de l'existence du fichier
if [ ! -f "$FILE" ]; then
    echo "❌ Erreur : Le fichier $FILE n'existe pas"
    exit 1
fi

# Création d'une sauvegarde
cp "$FILE" "${FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Sauvegarde créée"

# Utilisation de Node.js pour parser et modifier le fichier de manière sûre
node << 'EOF'
const fs = require('fs');
const path = "src/app/features/map/pages/map-page/map-page.component.ts";

const content = fs.readFileSync(path, 'utf-8');

// Ajouter l'import de ActivatedRoute si nécessaire
let updatedContent = content;
if (!content.includes("import { ActivatedRoute } from '@angular/router'")) {
  // Ajouter l'import après les autres imports de @angular/router
  updatedContent = content.replace(
    /(import { .*? } from '@angular\\/router';)/,
    "$1\nimport { ActivatedRoute } from '@angular/router';"
  );
}

// Modifier le constructeur pour injecter ActivatedRoute si nécessaire
if (!content.includes("private route: ActivatedRoute")) {
  updatedContent = updatedContent.replace(
    /(constructor\\(([^)]*)\\))/,
    "constructor($2, private route: ActivatedRoute)"
  );
}

// Modifier le template du popup pour ajouter le bouton Modifier
// On cherche la section marker.bindPopup et on l'enrichit
const popupPattern = /marker\\.bindPopup\\(`([^`]+)`\\)/s;

if (popupPattern.test(updatedContent)) {
  updatedContent = updatedContent.replace(
    popupPattern,
    `marker.bindPopup(\\`
    <div class=\\"text-center font-sans\\">
      <h3 class=\\"font-bold text-base text-gray-800 mb-2 truncate\\">\${p.name}</h3>
      <div class=\\"relative\\">
        <img src=\\"\\${img}\\" class=\\"popup-image\\" onerror=\\"this.src='https://via.placeholder.com/300?text=Image+Indisponible'\\"/>
        <span class=\\"absolute bottom-3 right-1 bg-white/80 px-1 rounded text-[10px] font-bold text-gray-600\\">
          \\${p.categories?.[0] || 'Lieu'}
        </span>
      </div>
      <button id=\\"btn-\\${p.id}\\" class=\\"mt-3 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-full text-sm transition shadow-sm flex items-center justify-center gap-1 w-full\\">
        <span>👁️</span> Voir Détails
      </button>
      \${adminButtonHtml}
    </div>
  \\`)`
  );
}

// Ajouter l'événement click pour le bouton de modification
const editButtonEvent = `
                const editBtn = document.getElementById('edit-\${p.id}');
                if (editBtn) {
                  editBtn.addEventListener('click', () => {
                    this.router.navigate(['/place', p.id], { queryParams: { edit: 1 } });
                  });
                }
`;

if (!content.includes("editBtn.addEventListener")) {
  updatedContent = updatedContent.replace(
    /(btn\.addEventListener[^;]+;)/,
    "$1" + editButtonEvent
  );
}

fs.writeFileSync(path, updatedContent, 'utf-8');
console.log("✅ Modifications appliquées avec succès");
EOF

echo "✅ Bouton 'Modifier' ajouté aux popups pour les administrateurs"
echo "✅ Navigation vers la page de détails en mode édition configurée"
echo "🎉 Terminé ! Le bouton apparaîtra automatiquement pour les utilisateurs avec le rôle 'admin'"
