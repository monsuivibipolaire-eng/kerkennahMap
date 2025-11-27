#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

TS_FILE="$ROOT/src/app/features/map/components/place-comments.component.ts"
HTML_FILE="$ROOT/src/app/features/map/components/place-comments.component.html"

echo "Racine projet : $ROOT"

############################################
# 1) Corriger le template HTML
############################################

if [[ -f "$HTML_FILE" ]]; then
  echo "-> Correction du template : $HTML_FILE"

  node <<'EOF'
const fs = require('fs');
const path = require('path');

const projectRoot = process.cwd();
const htmlPath = path.join(
  projectRoot,
  'src',
  'app',
  'features',
  'map',
  'components',
  'place-comments.component.html'
);

let html = fs.readFileSync(htmlPath, 'utf8');

// On remplace notre ancienne expression compliquée par un simple appel de méthode.
html = html.replace(
  /\{\{\s*\(\s*c\.createdAt\?\.\s*toDate\s*\?\s*c\.createdAt\.toDate\(\)\s*:\s*c\.createdAt\s*\)\s*\|\s*date:\s*'short'\s*\}\}/,
  "{{ toDate(c.createdAt) | date: 'short' }}"
);

// Variante avec moins d'espaces (au cas où)
html = html.replace(
  /\{\{\s*\(\s*c\.createdAt\?\.toDate\s*\?\s*c\.createdAt\.toDate\(\)\s*:\s*c\.createdAt\s*\)\s*\|\s*date:\s*'short'\s*\}\}/,
  "{{ toDate(c.createdAt) | date: 'short' }}"
);

fs.writeFileSync(htmlPath, html, 'utf8');
console.log("Template place-comments.component.html mis à jour.");
EOF

else
  echo "Fichier HTML introuvable : $HTML_FILE (étape ignorée)."
fi

############################################
# 2) Ajouter une méthode toDate() dans le TS
############################################

if [[ -f "$TS_FILE" ]]; then
  echo "-> Ajout de la méthode toDate() dans : $TS_FILE"

  node <<'EOF'
const fs = require('fs');
const path = require('path');

const projectRoot = process.cwd();
const tsPath = path.join(
  projectRoot,
  'src',
  'app',
  'features',
  'map',
  'components',
  'place-comments.component.ts'
);

let ts = fs.readFileSync(tsPath, 'utf8');

// Si la méthode existe déjà, on ne fait rien
if (ts.includes('toDate(value: any)')) {
  console.log("Méthode toDate(value: any) déjà présente, aucune modification TS.");
} else {
  const method = `
  toDate(value: any): any {
    if (!value) {
      return value;
    }
    const v: any = value as any;
    return v.toDate ? v.toDate() : v;
  }
`;

  // On insère la méthode juste avant la dernière accolade fermante du fichier
  if (ts.match(/}\s*$/)) {
    ts = ts.replace(/}\s*$/, method + '\n}\n');
    fs.writeFileSync(tsPath, ts, 'utf8');
    console.log("Méthode toDate(value: any) ajoutée à PlaceCommentsComponent.");
  } else {
    console.warn("Impossible de trouver la dernière '}' pour injecter la méthode. Fais-le à la main.");
  }
}
EOF

else
  echo "Fichier TS introuvable : $TS_FILE (étape ignorée)."
fi

echo "✅ Terminé. Relance 'ng serve' pour vérifier."
