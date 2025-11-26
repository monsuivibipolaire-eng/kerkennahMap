#!/usr/bin/env bash
set -euo pipefail

FILE="src/app/features/map/components/place-edit-modal.component.html"

if [ ! -f "$FILE" ]; then
  echo "❌ Fichier introuvable : $FILE"
  exit 1
fi

echo "➡️ Réécriture de $FILE avec gestion correcte du scroll dans la modale..."

cat > "$FILE" <<'HTML'
<div
  class="fixed inset-0 z-40 flex items-start justify-center bg-black/50 overflow-y-auto"
>
  <div
    class="bg-white rounded-xl shadow-xl max-w-3xl w-full mx-4 my-8 p-6 space-y-4"
    *ngIf="place"
  >
    <h2 class="text-lg font-semibold text-gray-900 mb-2">Modifier le lieu</h2>

    <!-- FORMULAIRE AU-DESSUS DE LA CARTE -->
    <form class="space-y-4" (ngSubmit)="onSubmit()">
      <!-- Nom -->
      <div class="space-y-1">
        <label class="block text-sm font-medium text-gray-700">Nom</label>
        <input
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
          [(ngModel)]="place.name"
          name="name"
          required
        />
      </div>

      <!-- Description -->
      <div class="space-y-1">
        <label class="block text-sm font-medium text-gray-700">Description</label>
        <textarea
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
          rows="3"
          [(ngModel)]="place.description"
          name="description"
          required
        ></textarea>
      </div>

      <!-- Catégories -->
      <div class="space-y-1">
        <label class="block text-sm font-medium text-gray-700">Catégories</label>
        <select
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm"
          multiple
          [(ngModel)]="place.categories"
          name="categories"
        >
          <option *ngFor="let c of categories" [ngValue]="c">{{ c }}</option>
        </select>
        <p class="text-xs text-gray-500 mt-1">
          Maintiens Ctrl (ou Cmd sur Mac) pour sélectionner plusieurs catégories.
        </p>
      </div>

      <!-- Images -->
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700">Images</label>

        <div
          *ngIf="place.images?.length; else noImages"
          class="grid grid-cols-2 gap-2"
        >
          <div
            *ngFor="let img of place.images"
            class="relative border rounded-md overflow-hidden"
          >
            <img
              [src]="img"
              alt="Image du lieu"
              class="w-full h-24 object-cover"
            />
            <button
              type="button"
              (click)="removeImage(img)"
              class="absolute top-1 right-1 bg-red-600 text-white text-xs px-2 py-0.5 rounded"
            >
              Supprimer
            </button>
          </div>
        </div>
        <ng-template #noImages>
          <p class="text-xs text-gray-500">Aucune image pour le moment.</p>
        </ng-template>

        <div class="flex items-center gap-2 text-xs text-gray-600">
          <input
            type="file"
            accept="image/*"
            multiple
            (change)="onImagesSelected($event)"
          />
          <span *ngIf="uploadingImages">Upload des images...</span>
        </div>
      </div>

      <!-- Vidéos -->
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700">Vidéos</label>

        <div *ngIf="place.videos?.length; else noVideos" class="space-y-1">
          <div
            *ngFor="let vid of place.videos"
            class="flex items-center justify-between border rounded-md px-3 py-1 text-xs"
          >
            <a
              [href]="vid"
              target="_blank"
              rel="noopener"
              class="text-blue-600 truncate mr-2"
            >
              {{ vid }}
            </a>
            <button
              type="button"
              (click)="removeVideo(vid)"
              class="bg-red-600 text-white text-xs px-2 py-0.5 rounded"
            >
              Supprimer
            </button>
          </div>
        </div>
        <ng-template #noVideos>
          <p class="text-xs text-gray-500">Aucune vidéo pour le moment.</p>
        </ng-template>

        <div class="flex items-center gap-2 text-xs text-gray-600">
          <input
            type="file"
            accept="video/*"
            multiple
            (change)="onVideosSelected($event)"
          />
          <span *ngIf="uploadingVideos">Upload des vidéos...</span>
        </div>
      </div>

      <!-- Erreurs upload -->
      <div *ngIf="uploadError" class="text-xs text-red-600">
        {{ uploadError }}
      </div>

      <!-- Boutons -->
      <div class="flex justify-end gap-2 pt-2">
        <button
          type="button"
          class="px-4 py-1.5 rounded-md border border-gray-300 text-sm text-gray-700 hover:bg-gray-50"
          (click)="onCancel()"
          [disabled]="isSaving"
        >
          Annuler
        </button>

        <button
          type="submit"
          class="px-4 py-1.5 rounded-md bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 disabled:opacity-60"
          [disabled]="isSaving"
        >
          <ng-container *ngIf="!isSaving; else savingTpl">
            Enregistrer
          </ng-container>
          <ng-template #savingTpl>Enregistrement...</ng-template>
        </button>
      </div>
    </form>

    <!-- CARTE EN DESSOUS DU FORMULAIRE -->
    <div class="pt-4">
      <app-place-map-card
        [mapOptions]="mapOptions"
        [mapLayers]="mapLayers"
      ></app-place-map-card>
    </div>
  </div>
</div>
HTML

echo "✅ Scroll de la modale corrigé (contenu scrollable, formulaire au-dessus de la carte)."
