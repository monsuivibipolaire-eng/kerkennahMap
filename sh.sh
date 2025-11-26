#!/usr/bin/env bash
set -euo pipefail

TS_FILE="src/app/features/map/pages/place-detail/place-detail.component.ts"

if [ ! -f "$TS_FILE" ]; then
  echo "❌ Fichier introuvable : $TS_FILE"
  exit 1
fi

echo "➡️ Mise à jour de onSubmitComment dans $TS_FILE pour afficher immédiatement le commentaire"

python3 - << 'PY'
from pathlib import Path
import re

ts_path = Path("src/app/features/map/pages/place-detail/place-detail.component.ts")
src = ts_path.read_text(encoding="utf-8")

impl = """
  // ===== Auto-wired handler: ajoute le commentaire dans la liste locale =====
  onSubmitComment(event: { rating: number; text: string }) {
    (this as any).isSubmittingComment = true;

    const newComment: any = {
      rating: event.rating,
      comment: event.text,
      userName: (this as any).currentUserName ?? 'Vous',
      createdAt: new Date().toISOString()
    };

    const current = (this as any).comments || [];
    (this as any).comments = [newComment, ...current];

    (this as any).isSubmittingComment = false;
  }
"""

# 1) Si une méthode onSubmitComment existe déjà, on la remplace entièrement
pattern = r"onSubmitComment\s*\([^)]*\)\s*\{.*?\}"
m = re.search(pattern, src, flags=re.DOTALL)

if m:
    new_src = src[:m.start()] + impl + src[m.end():]
    ts_path.write_text(new_src, encoding="utf-8")
    print("✅ Méthode onSubmitComment existante remplacée.")
else:
    # 2) Sinon on insère la méthode avant la dernière '}' (fermeture de classe)
    idx = src.rfind("}")
    if idx == -1:
        raise SystemExit("❌ Impossible de trouver la fermeture de classe '}' dans le fichier TS.")

    new_src = src[:idx] + impl + "\n}" + src[idx+1:]
    ts_path.write_text(new_src, encoding="utf-8")
    print("✅ Méthode onSubmitComment ajoutée à la fin de la classe.")
PY

echo "✅ Terminé. Relance maintenant ton app (ng serve / npm run start) et teste l'ajout d'un commentaire."
