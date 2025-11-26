#!/usr/bin/env bash
set -euo pipefail

TS_FILE="src/app/features/map/pages/place-detail/place-detail.component.ts"

if [ ! -f "$TS_FILE" ]; then
  echo "❌ Fichier introuvable : $TS_FILE"
  exit 1
fi

echo "➡️ Correction des handlers / propriété dans $TS_FILE"

python3 - << 'PY'
from pathlib import Path

ts_path = Path("src/app/features/map/pages/place-detail/place-detail.component.ts")
src = ts_path.read_text(encoding="utf-8")

missing_any = False

def has(snippet: str) -> bool:
    return snippet in src

# Construire les morceaux manquants
parts = []

if "isSavingPlace" not in src:
    missing_any = True
    parts.append(
        "  // Auto-added: flag to indicate saving state for edit modal\n"
        "  isSavingPlace = false;\n\n"
    )

if "onUploadImages(" not in src:
    missing_any = True
    parts.append(
        "  // Auto-added stub: called by app-place-media-gallery (addImages)\n"
        "  onUploadImages(files: FileList) {\n"
        "    // TODO: implémenter la logique d'upload d'images\n"
        "    console.warn('[PlaceDetailComponent] onUploadImages stub - implement me', files);\n"
        "  }\n\n"
    )

if "onUploadVideos(" not in src:
    missing_any = True
    parts.append(
        "  // Auto-added stub: called by app-place-media-gallery (addVideos)\n"
        "  onUploadVideos(files: FileList) {\n"
        "    // TODO: implémenter la logique d'upload de vidéos\n"
        "    console.warn('[PlaceDetailComponent] onUploadVideos stub - implement me', files);\n"
        "  }\n\n"
    )

if "onSubmitComment(" not in src:
    missing_any = True
    parts.append(
        "  // Auto-added stub: called by app-place-comments (submitComment)\n"
        "  onSubmitComment(event: { rating: number; text: string }) {\n"
        "    // TODO: implémenter la logique d’envoi de commentaire\n"
        "    console.warn('[PlaceDetailComponent] onSubmitComment stub - implement me', event);\n"
        "  }\n\n"
    )

if "onSaveEditedPlace(" not in src:
    missing_any = True
    parts.append(
        "  // Auto-added stub: called by app-place-edit-modal (save)\n"
        "  onSaveEditedPlace(updatedPlace: any) {\n"
        "    // TODO: implémenter la logique de sauvegarde du lieu (appel API, etc.)\n"
        "    console.warn('[PlaceDetailComponent] onSaveEditedPlace stub - implement me', updatedPlace);\n"
        "  }\n\n"
    )

if not parts:
    print("✅ Tous les handlers / propriétés sont déjà présents. Rien à faire.")
else:
    # On insère avant la dernière '}' du fichier (fermeture de la classe)
    idx = src.rfind("}")
    if idx == -1:
        raise SystemExit("❌ Impossible de trouver une '}' de fin dans le fichier TS.")

    insert = (
        "\n  // ===== Auto-added handlers for place-detail refactor =====\n"
        + "".join(parts) +
        "  // ===== End of auto-added handlers =====\n\n"
    )

    new_src = src[:idx] + insert + src[idx:]
    ts_path.write_text(new_src, encoding="utf-8")
    print("✅ Handlers manquants ajoutés dans PlaceDetailComponent.")
PY

echo "➡️ Terminé. Relance ton build (ng serve / npm run start) pour vérifier."
