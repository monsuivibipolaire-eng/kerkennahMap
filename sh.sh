#!/usr/bin/env bash
set -euo pipefail

ROOT="src/app/features/map"
PAGE_DIR="$ROOT/pages/place-detail"
COMP_DIR="$ROOT/components"

DETAIL_HTML="$PAGE_DIR/place-detail.component.html"
HEADER_HTML="$COMP_DIR/place-header.component.html"
INFO_HTML="$COMP_DIR/place-info.component.html"
COMMENTS_HTML="$COMP_DIR/place-comments.component.html"
MEDIA_TS="$COMP_DIR/place-media-gallery.component.ts"
MEDIA_HTML="$COMP_DIR/place-media-gallery.component.html"

echo "➡️ Vérification des fichiers..."

for f in "$DETAIL_HTML" "$HEADER_HTML" "$INFO_HTML" "$COMMENTS_HTML" "$MEDIA_TS" "$MEDIA_HTML"; do
  if [ ! -f "$f" ]; then
    echo "❌ Fichier introuvable : $f"
    exit 1
  fi
done

echo "➡️ Backup des fichiers originaux (*.bak)..."

for f in "$DETAIL_HTML" "$HEADER_HTML" "$INFO_HTML" "$COMMENTS_HTML" "$MEDIA_TS" "$MEDIA_HTML"; do
  cp "$f" "$f.bak"
done

########################################
# 1) place-detail.component.html
#    - Actions admin en haut de page
#    - media-gallery reçoit [editMode] lié à showEditModal
########################################
cat > "$DETAIL_HTML" << 'EOF'
<ng-container *ngIf="place$ | async as place; else loading">
  <div class="min-h-screen bg-gray-50 pb-12">

    <!-- BARRE ACTIONS ADMIN EN HAUT -->
    <div class="max-w-6xl mx-auto px-4 pt-6 flex justify-end" *ngIf="isAdmin">
      <app-place-admin-actions
        [place]="place"
        [isAdmin]="isAdmin"
        (edit)="openEditModal($event)"
        (delete)="onDeletePlace($event)">
      </app-place-admin-actions>
    </div>

    <!-- HEADER / HERO -->
    <app-place-header
      [place]="place"
      [averageRating]="averageRating"
      [commentsCount]="comments.length">
    </app-place-header>

    <div class="max-w-6xl mx-auto px-4 mt-6 grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- COLONNE PRINCIPALE -->
      <div class="space-y-6 lg:col-span-2">
        <app-place-media-gallery
          [place]="place"
          [uploadingImages]="uploadingImages"
          [uploadingVideos]="uploadingVideos"
          [uploadError]="uploadError"
          [editMode]="showEditModal"
          (addImages)="onUploadImages($event)"
          (addVideos)="onUploadVideos($event)">
        </app-place-media-gallery>

        <app-place-info
          [place]="place">
        </app-place-info>

        <app-place-comments
          [comments]="comments"
          [isLoggedIn]="isLoggedIn"
          [currentUserName]="currentUserName"
          [isSubmitting]="isSubmittingComment"
          (submitComment)="onSubmitComment($event)">
        </app-place-comments>
      </div>

      <!-- COLONNE LATÉRALE -->
      <div class="space-y-6">
        <app-place-map-card
          [mapOptions]="mapOptions"
          [mapLayers]="mapLayers">
        </app-place-map-card>
      </div>
    </div>

    <app-place-edit-modal
      *ngIf="showEditModal"
      [place]="editingPlace"
      [categories]="availableCategories"
      [isSaving]="isSavingPlace"
      [uploadError]="uploadError"
      (cancel)="closeEditModal()"
      (save)="onSaveEditedPlace($event)">
    </app-place-edit-modal>
  </div>
</ng-container>

<ng-template #loading>
  <div class="min-h-screen flex items-center justify-center text-gray-500">
    Chargement du lieu...
  </div>
</ng-template>
EOF

echo "✅ place-detail.component.html mis à jour"

########################################
# 2) place-header.component.html
#    - Catégories en haut dans l'image de header
########################################
cat > "$HEADER_HTML" << 'EOF'
<div class="relative h-64 md:h-96 w-full bg-gray-800 overflow-hidden" *ngIf="place as p">
  <img
    *ngIf="p.images && p.images.length > 0"
    [src]="p.images[0]"
    class="w-full h-full object-cover opacity-70"
    [alt]="p.name"
  />

  <div
    *ngIf="!p.images || p.images.length === 0"
    class="absolute inset-0 bg-gradient-to-r from-blue-900 to-blue-700 opacity-80"
  ></div>

  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent"></div>

  <!-- Bandeau haut : catégories + statut -->
  <div class="absolute top-4 left-4 right-4 z-20 flex items-start justify-between gap-4">
    <div class="flex flex-wrap gap-2">
      <span
        *ngFor="let cat of p.categories"
        class="px-3 py-1 rounded-full text-xs font-semibold bg-black/60 text-white uppercase tracking-wide border border-white/20"
      >
        {{ cat }}
      </span>
    </div>

    <span
      class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold"
      [ngClass]="{
        'bg-yellow-400 text-gray-900': p.status === 'pending',
        'bg-green-500 text-white': p.status === 'approved',
        'bg-red-500 text-white': p.status === 'rejected'
      }"
    >
      <ng-container [ngSwitch]="p.status">
        <span *ngSwitchCase="'pending'">⏳ En attente</span>
        <span *ngSwitchCase="'approved'">✅ Validé</span>
        <span *ngSwitchCase="'rejected'">❌ Rejeté</span>
        <span *ngSwitchDefault>ℹ️ Statut inconnu</span>
      </ng-container>
    </span>
  </div>

  <div class="relative z-10 max-w-5xl mx-auto px-4 md:px-8 h-full flex flex-col justify-end pb-8">
    <h1 class="text-3xl md:text-4xl font-extrabold text-white mb-3 drop-shadow-lg">
      {{ p.name }}
    </h1>

    <div class="flex flex-wrap items-center gap-3 text-sm text-gray-100">
      <div class="flex items-center gap-1" *ngIf="averageRating !== null">
        <span class="text-yellow-300">★</span>
        <span class="font-semibold">{{ averageRating }}</span>
        <span class="text-gray-300">/ 5</span>
        <span class="text-gray-300">•</span>
        <span>{{ commentsCount }} avis</span>
      </div>
    </div>
  </div>
</div>
EOF

echo "✅ place-header.component.html mis à jour"

########################################
# 3) place-info.component.html
#    - Suppression de la section "Localisation"
########################################
cat > "$INFO_HTML" << 'EOF'
<div *ngIf="place as p" class="bg-white rounded-xl shadow-sm p-4 md:p-6 space-y-4">
  <h2 class="text-lg font-semibold text-gray-900">À propos de ce lieu</h2>

  <p class="text-sm text-gray-700 whitespace-pre-line">
    {{ p.description }}
  </p>

  <div class="space-y-3 text-sm text-gray-700">
    <div>
      <div class="font-semibold text-gray-900 mb-1">Catégories</div>
      <div class="flex flex-wrap gap-1">
        <span
          *ngFor="let cat of p.categories"
          class="inline-flex items-center px-2 py-0.5 rounded-full bg-blue-50 text-xs text-blue-700 border border-blue-100"
        >
          {{ cat }}
        </span>
      </div>
    </div>
  </div>

  <div class="border-t border-gray-100 pt-3 text-xs text-gray-500 space-y-1">
    <div>Créé le : {{ p.createdAt | date: 'short' }}</div>
    <div *ngIf="p.updatedAt">Mis à jour le : {{ p.updatedAt | date: 'short' }}</div>
    <div *ngIf="p.validatedBy">
      Validé par : {{ p.validatedBy }}
      <span *ngIf="p.validatedAt">• le {{ p.validatedAt | date: 'short' }}</span>
    </div>
  </div>
</div>
EOF

echo "✅ place-info.component.html mis à jour"

########################################
# 4) place-comments.component.html
#    - “Votre note” = 5 étoiles cliquables
########################################
cat > "$COMMENTS_HTML" << 'EOF'
<div class="bg-white rounded-xl shadow-sm p-4 md:p-6 space-y-4">
  <h2 class="text-lg font-semibold text-gray-900">Avis et commentaires</h2>

  <div *ngIf="isLoggedIn; else mustLogin" class="space-y-3">
    <div class="flex items-center gap-2 text-sm">
      <span class="font-medium">Votre note :</span>

      <div class="flex items-center gap-1">
        <button
          *ngFor="let r of [1,2,3,4,5]"
          type="button"
          class="text-xl focus:outline-none"
          (click)="newRating = r"
        >
          <span
            [ngClass]="{
              'text-yellow-400': newRating >= r,
              'text-gray-300': newRating < r
            }"
          >
            ★
          </span>
        </button>
        <span class="text-xs text-gray-500 ml-2">{{ newRating }}/5</span>
      </div>
    </div>

    <textarea
      class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      rows="3"
      [(ngModel)]="newText"
      placeholder="Partage ton expérience..."
    ></textarea>

    <button
      type="button"
      class="px-4 py-2 rounded-md bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 disabled:opacity-60"
      [disabled]="isSubmitting || !newText.trim()"
      (click)="onSubmit()"
    >
      <ng-container *ngIf="!isSubmitting; else submitting">
        Publier mon avis
      </ng-container>
      <ng-template #submitting>Envoi...</ng-template>
    </button>
  </div>

  <ng-template #mustLogin>
    <p class="text-sm text-gray-600">
      Connecte-toi pour laisser un commentaire.
    </p>
  </ng-template>

  <div class="border-t border-gray-100 pt-4 space-y-3" *ngIf="comments.length > 0; else noComments">
    <div
      *ngFor="let c of comments"
      class="pb-3 border-b border-gray-100 last:border-none last:pb-0"
    >
      <div class="flex items-center justify-between mb-1">
        <div class="font-semibold text-sm text-gray-900">
          {{ c.userName || 'Utilisateur' }}
        </div>
        <div class="flex items-center gap-1 text-xs text-gray-600">
          <span class="text-yellow-400">★</span>
          <span class="font-semibold">{{ c.rating }}</span>
        </div>
      </div>
      <p class="text-sm text-gray-700 whitespace-pre-line">
        {{ c.comment }}
      </p>
      <div class="mt-1 text-xs text-gray-400">
        {{ c.createdAt | date: 'short' }}
      </div>
    </div>
  </div>

  <ng-template #noComments>
    <p class="text-sm text-gray-500">
      Aucun avis pour le moment. Sois le premier à partager ton expérience !
    </p>
  </ng-template>
</div>
EOF

echo "✅ place-comments.component.html mis à jour"

########################################
# 5) place-media-gallery.component.ts
#    - Ajout editMode + lightbox plein écran
########################################
cat > "$MEDIA_TS" << 'EOF'
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-media-gallery',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './place-media-gallery.component.html'
})
export class PlaceMediaGalleryComponent {
  @Input() place: Place | undefined;
  @Input() uploadingImages = false;
  @Input() uploadingVideos = false;
  @Input() uploadError: string | null = null;

  // Afficher les champs d'upload seulement en mode édition
  @Input() editMode = false;

  @Output() addImages = new EventEmitter<FileList>();
  @Output() addVideos = new EventEmitter<FileList>();

  // État pour la galerie plein écran
  isLightboxOpen = false;
  lightboxType: 'image' | 'video' | null = null;
  lightboxIndex = 0;

  get images(): string[] {
    return this.place?.images ?? [];
  }

  get videos(): string[] {
    // selon ton modèle, adapte le champ (videos, mediaVideos, etc.)
    // @ts-ignore
    return this.place?.videos ?? [];
  }

  onImagesSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length) {
      this.addImages.emit(input.files);
    }
  }

  onVideosSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length) {
      this.addVideos.emit(input.files);
    }
  }

  openImage(index: number) {
    if (this.images.length === 0) {
      return;
    }
    this.lightboxType = 'image';
    this.lightboxIndex = index;
    this.isLightboxOpen = true;
  }

  openVideo(index: number) {
    if (this.videos.length === 0) {
      return;
    }
    this.lightboxType = 'video';
    this.lightboxIndex = index;
    this.isLightboxOpen = true;
  }

  closeLightbox() {
    this.isLightboxOpen = false;
  }

  next() {
    if (!this.lightboxType) return;

    if (this.lightboxType === 'image' && this.images.length > 0) {
      this.lightboxIndex = (this.lightboxIndex + 1) % this.images.length;
    } else if (this.lightboxType === 'video' && this.videos.length > 0) {
      this.lightboxIndex = (this.lightboxIndex + 1) % this.videos.length;
    }
  }

  prev() {
    if (!this.lightboxType) return;

    if (this.lightboxType === 'image' && this.images.length > 0) {
      this.lightboxIndex =
        (this.lightboxIndex - 1 + this.images.length) % this.images.length;
    } else if (this.lightboxType === 'video' && this.videos.length > 0) {
      this.lightboxIndex =
        (this.lightboxIndex - 1 + this.videos.length) % this.videos.length;
    }
  }
}
EOF

echo "✅ place-media-gallery.component.ts mis à jour"

########################################
# 6) place-media-gallery.component.html
#    - Thumbnails + lightbox plein écran
#    - Upload visible uniquement en mode édition
########################################
cat > "$MEDIA_HTML" << 'EOF'
<div *ngIf="place as p" class="bg-white rounded-xl shadow-sm p-4 md:p-6 space-y-4">
  <h2 class="text-lg font-semibold text-gray-900">Médias</h2>

  <!-- Grille de vignettes -->
  <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
    <ng-container *ngFor="let img of images; let i = index">
      <button
        type="button"
        class="relative group w-full h-32 md:h-40 rounded-md overflow-hidden border border-gray-100 focus:outline-none"
        (click)="openImage(i)"
      >
        <img
          [src]="img"
          class="w-full h-full object-cover"
          alt="Image du lieu"
        />
        <div class="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-sm font-semibold transition-opacity">
          Voir
        </div>
      </button>
    </ng-container>

    <ng-container *ngFor="let vid of videos; let i = index">
      <button
        type="button"
        class="relative group w-full h-32 md:h-40 rounded-md overflow-hidden border border-gray-100 focus:outline-none"
        (click)="openVideo(i)"
      >
        <video
          [src]="vid"
          class="w-full h-full object-cover"
          muted
        ></video>
        <div class="absolute inset-0 bg-black/40 flex items-center justify-center text-white text-sm font-semibold">
          ▶ Voir la vidéo
        </div>
      </button>
    </ng-container>
  </div>

  <!-- Zone d'upload visible uniquement en mode édition -->
  <div *ngIf="editMode" class="border-t border-gray-100 pt-4 space-y-2 text-sm">
    <div class="flex flex-col md:flex-row gap-2 md:items-center">
      <label class="text-sm font-medium text-gray-700">Ajouter des images :</label>
      <input
        type="file"
        accept="image/*"
        multiple
        (change)="onImagesSelected($event)"
      />
      <span *ngIf="uploadingImages" class="text-xs text-gray-500">Upload images...</span>
    </div>

    <div class="flex flex-col md:flex-row gap-2 md:items-center">
      <label class="text-sm font-medium text-gray-700">Ajouter des vidéos :</label>
      <input
        type="file"
        accept="video/*"
        multiple
        (change)="onVideosSelected($event)"
      />
      <span *ngIf="uploadingVideos" class="text-xs text-gray-500">Upload vidéos...</span>
    </div>

    <div *ngIf="uploadError" class="text-xs text-red-600">
      {{ uploadError }}
    </div>
  </div>
</div>

<!-- Lightbox plein écran -->
<div
  class="fixed inset-0 z-40 bg-black/80 flex items-center justify-center"
  *ngIf="isLightboxOpen"
>
  <button
    type="button"
    class="absolute top-4 right-4 text-white text-2xl px-3 py-1 rounded-full bg-black/50"
    (click)="closeLightbox()"
  >
    ✕
  </button>

  <button
    type="button"
    class="absolute left-4 md:left-10 text-white text-3xl px-3 py-2 rounded-full bg-black/40"
    (click)="prev()"
  >
    ‹
  </button>

  <button
    type="button"
    class="absolute right-4 md:right-10 text-white text-3xl px-3 py-2 rounded-full bg-black/40"
    (click)="next()"
  >
    ›
  </button>

  <div class="max-w-5xl w-full px-4">
    <ng-container [ngSwitch]="lightboxType">
      <img
        *ngSwitchCase="'image'"
        [src]="images[lightboxIndex]"
        class="w-full max-h-[80vh] object-contain rounded-lg shadow-lg"
        alt="Media du lieu"
      />

      <video
        *ngSwitchCase="'video'"
        [src]="videos[lightboxIndex]"
        class="w-full max-h-[80vh] rounded-lg shadow-lg"
        controls
        autoplay
      ></video>
    </ng-container>
  </div>
</div>
EOF

echo "✅ place-media-gallery.component.html mis à jour"

echo
echo "🎉 Mise à jour terminée."
echo "Des backups ont été créés avec l'extension .bak."
echo "Relance maintenant ton build (ng serve / npm run start) pour voir le nouveau comportement."
