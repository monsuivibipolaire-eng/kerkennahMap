#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    cp "$f" "$f.bak.$(date +%Y%m%d_%H%M%S)"
  fi
}

echo "📦 Backup des fichiers..."
backup "src/app/core/services/places.service.ts"
backup "src/app/features/map/pages/place-detail/place-detail.component.ts"
backup "src/app/features/map/pages/place-detail/place-detail.component.html"

########################################
# 1) Service PlacesService : updatePlace
########################################
cat > src/app/core/services/places.service.ts <<'EOF'
import { Injectable, inject } from '@angular/core';
import { Firestore, collection, collectionData, doc, docData, addDoc, query, where, updateDoc } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Place } from '../models/place.model';

@Injectable({
  providedIn: 'root'
})
export class PlacesService {
  private firestore: Firestore = inject(Firestore);

  constructor() {}

  // Récupérer tous les lieux approuvés
  getApprovedPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'approved'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // Récupérer un lieu par son ID
  getPlaceById(id: string): Observable<Place | undefined> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return docData(placeDocRef, { idField: 'id' }) as Observable<Place>;
  }

  // Mettre à jour un lieu existant
  updatePlace(id: string, data: Partial<Place>): Promise<void> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return updateDoc(placeDocRef, data as any);
  }

  // Ajouter un nouveau lieu
  addPlace(place: Place): Promise<any> {
    const placesRef = collection(this.firestore, 'places');
    return addDoc(placesRef, place);
  }

  // Admin: Récupérer les lieux en attente
  getPendingPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'pending'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }
}
EOF

########################################
# 2) Component TS : admin, modal, images
########################################
cat > src/app/features/map/pages/place-detail/place-detail.component.ts <<'EOF'
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import * as L from 'leaflet';
import { Observable, of } from 'rxjs';
import { switchMap, tap } from 'rxjs/operators';
import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../../../core/services/auth.service';
import { SupabaseImageService } from '../../../../core/services/supabase-image.service';

@Component({
  selector: 'app-place-detail',
  standalone: true,
  imports: [CommonModule, LeafletModule, RouterModule, FormsModule],
  templateUrl: './place-detail.component.html',
  styleUrls: ['./place-detail.component.css']
})
export class PlaceDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private placesService = inject(PlacesService);
  private authService = inject(AuthService);
  private supabaseImageService = inject(SupabaseImageService);

  place$: Observable<Place | undefined> = of(undefined);

  // 🔐 visible uniquement si ADMIN
  isAdmin = false;

  // 🟡 Modal d'édition
  showEditModal = false;
  editingPlace: Place | null = null;

  // Catégories proposées
  availableCategories: string[] = [
    'café',
    'restaurant',
    'parc',
    'plage',
    'monument',
    'hébergement'
  ];

  // Upload images
  uploadingImages = false;
  uploadError: string | null = null;

  // Options de carte
  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18
      })
    ],
    zoom: 14,
    center: L.latLng(34.71, 11.15)
  };

  mapLayers: L.Layer[] = [];

  constructor() {
    // Patch Icônes Leaflet (au cas où)
    const iconRetinaUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png';
    const iconUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png';
    const shadowUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png';
    L.Marker.prototype.options.icon = L.icon({
      iconRetinaUrl,
      iconUrl,
      shadowUrl,
      iconSize: [25, 41],
      iconAnchor: [12, 41],
      popupAnchor: [1, -34],
      tooltipAnchor: [16, -28],
      shadowSize: [41, 41]
    });
  }

  ngOnInit(): void {
    // 1) Savoir si l'utilisateur est admin
    this.authService.user$.subscribe(user => {
      const roles = (user as any)?.roles;
      this.isAdmin = !!roles && Array.isArray(roles) && roles.includes('admin');
    });

    // 2) Charger la place depuis l'ID de l'URL
    this.place$ = this.route.paramMap.pipe(
      switchMap(params => {
        const id = params.get('id');
        if (id) {
          return this.placesService.getPlaceById(id);
        }
        return of(undefined);
      }),
      tap(place => {
        if (place) {
          this.updateMap(place);
        }
      })
    );
  }

  updateMap(place: Place) {
    // Centrer la carte
    this.mapOptions = {
      ...this.mapOptions,
      center: L.latLng(place.latitude, place.longitude)
    };

    // Ajouter le marqueur
    this.mapLayers = [
      L.marker([place.latitude, place.longitude]).bindPopup(place.name)
    ];
  }

  // Ouvre la modal avec une copie de la place
  openEditModal(place: Place) {
    this.uploadError = null;
    this.editingPlace = {
      ...place,
      images: [...(place.images || [])],
      categories: [...(place.categories || [])]
    };
    this.showEditModal = true;
  }

  // Toggle des catégories via checkbox
  toggleCategory(cat: string, event: Event) {
    if (!this.editingPlace) return;
    const input = event.target as HTMLInputElement;
    const checked = input.checked;

    const current = this.editingPlace.categories ?? [];
    if (checked) {
      if (!current.includes(cat)) {
        this.editingPlace = {
          ...this.editingPlace,
          categories: [...current, cat]
        };
      }
    } else {
      this.editingPlace = {
        ...this.editingPlace,
        categories: current.filter(c => c !== cat)
      };
    }
  }

  // Upload de nouvelles images vers Supabase
  async onFilesSelected(event: Event) {
    if (!this.editingPlace) return;
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const files = Array.from(input.files);
    this.uploadingImages = true;
    this.uploadError = null;

    try {
      const newUrls: string[] = [];
      for (const file of files) {
        const safeName = file.name.replace(/\s+/g, '-').toLowerCase();
        const idPart = this.editingPlace.id || 'temp';
        const path = `${idPart}/${Date.now()}-${safeName}`;
        const url = await this.supabaseImageService.uploadImage(file, path);
        if (url) {
          newUrls.push(url);
        }
      }

      this.editingPlace = {
        ...this.editingPlace,
        images: [ ...(this.editingPlace.images || []), ...newUrls ]
      };

      // reset input
      input.value = '';
    } catch (err) {
      console.error('Erreur upload images', err);
      this.uploadError = "Erreur lors de l'upload des images.";
    } finally {
      this.uploadingImages = false;
    }
  }

  // Retirer une image de la place (ne supprime pas du stockage Supabase)
  removeExistingImage(url: string) {
    if (!this.editingPlace) return;
    this.editingPlace = {
      ...this.editingPlace,
      images: (this.editingPlace.images || []).filter(img => img !== url)
    };
  }

  closeEditModal() {
    this.showEditModal = false;
    this.editingPlace = null;
    this.uploadError = null;
    this.uploadingImages = false;
  }

  // Sauvegarde Firestore + refresh des données
  async savePlace() {
    if (!this.editingPlace || !this.editingPlace.id) {
      return;
    }

    const id = this.editingPlace.id;
    const payload: Partial<Place> = {
      name: this.editingPlace.name,
      description: this.editingPlace.description,
      latitude: this.editingPlace.latitude,
      longitude: this.editingPlace.longitude,
      categories: this.editingPlace.categories || [],
      images: this.editingPlace.images || [],
      updatedAt: new Date()
    };

    try {
      await this.placesService.updatePlace(id, payload);
      this.closeEditModal();

      // Recharge la place (et la carte)
      this.place$ = this.placesService.getPlaceById(id).pipe(
        tap(place => {
          if (place) {
            this.updateMap(place);
          }
        })
      );
    } catch (e) {
      console.error('Erreur update place', e);
    }
  }
}
EOF

########################################
# 3) Template HTML : bouton + modal + images
########################################
cat > src/app/features/map/pages/place-detail/place-detail.component.html <<'EOF'
<div class="min-h-screen bg-gray-50 pb-12" *ngIf="place$ | async as place; else loading">

  <!-- Hero -->
  <div class="relative h-64 md:h-96 w-full bg-gray-800 overflow-hidden">
    <!-- Image principale -->
    <img *ngIf="place.images && place.images.length > 0"
         [src]="place.images[0]"
         class="w-full h-full object-cover opacity-70"
         alt="{{ place.name }}">

    <div *ngIf="!place.images || place.images.length === 0"
         class="absolute inset-0 bg-gradient-to-r from-blue-900 to-blue-700 opacity-80">
    </div>

    <!-- Overlay titre -->
    <div class="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-black/80 to-transparent">
      <div class="container mx-auto">
        <div class="flex flex-wrap gap-2 mb-3">
          <span *ngFor="let cat of place.categories"
                class="bg-yellow-400 text-blue-900 text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wide">
            {{ cat }}
          </span>
        </div>

        <div class="flex flex-col md:flex-row md:items-center gap-3">
          <h1 class="text-3xl md:text-5xl font-bold text-white drop-shadow-md">
            {{ place.name }}
          </h1>

          <!-- 🟡 Bouton ADMIN seulement -->
          <button
            *ngIf="isAdmin"
            type="button"
            (click)="openEditModal(place)"
            class="md:ml-auto inline-flex items-center gap-2 px-4 py-2 rounded-full bg-yellow-400 text-gray-900 text-xs md:text-sm font-semibold shadow-lg hover:bg-yellow-300 transition">
            ✏️ Modifier cette place
          </button>
        </div>
      </div>
    </div>

    <!-- Bouton retour -->
    <a routerLink="/"
       class="absolute top-4 left-4 bg-white/10 hover:bg-white/20 border border-white/40 backdrop-blur text-white p-2 rounded-full transition">
      <svg xmlns="http://www.w3.org/2000/svg"
           class="h-6 w-6"
           fill="none"
           viewBox="0 0 24 24"
           stroke="currentColor">
        <path stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 19l-7-7m0 0l7-7m-7 7h18" />
      </svg>
    </a>
  </div>

  <!-- Contenu -->
  <div class="container mx-auto mt-8 px-4 md:px-0">
    <div class="grid md:grid-cols-3 gap-8">
      <!-- Colonne principale -->
      <div class="md:col-span-2 space-y-6">
        <div class="bg-white rounded-2xl shadow-sm p-6">
          <h2 class="text-xl font-semibold text-gray-800 mb-2 border-b pb-2">
            À propos
          </h2>
          <p class="text-gray-700 leading-relaxed">
            {{ place.description || 'Aucune description pour l’instant.' }}
          </p>
        </div>

        <!-- Galerie -->
        <div *ngIf="place.images && place.images.length > 1"
             class="bg-white rounded-2xl shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-3">
            Galerie photos
          </h3>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <img *ngFor="let img of place.images"
                 [src]="img"
                 class="w-full h-32 md:h-40 object-cover rounded-xl border border-gray-200 hover:opacity-90 transition"
                 alt="Photo de {{ place.name }}">
          </div>
        </div>
      </div>

      <!-- Colonne latérale (carte + actions) -->
      <div class="space-y-6">
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div class="px-4 py-3 bg-blue-50 border-b border-blue-100">
            <h3 class="font-bold text-blue-900 text-sm">Localisation</h3>
          </div>
          <div class="h-64 w-full relative z-0">
            <div class="h-full w-full"
                 leaflet
                 [leafletOptions]="mapOptions"
                 [leafletLayers]="mapLayers">
            </div>
          </div>
          <div class="p-4 bg-gray-50 text-xs text-gray-600 flex flex-col gap-1">
            <div>
              <span class="font-semibold">Latitude :</span> {{ place.latitude | number:'1.4-4' }}
            </div>
            <div>
              <span class="font-semibold">Longitude :</span> {{ place.longitude | number:'1.4-4' }}
            </div>
          </div>
        </div>

        <!-- Lien Google Maps -->
        <a class="block w-full bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium px-4 py-3 rounded-lg shadow flex items-center justify-center gap-2"
           [href]="'https://www.google.com/maps/search/?api=1&query=' + place.latitude + ',' + place.longitude"
           target="_blank"
           rel="noopener noreferrer">
          🗺️ Y aller (Google Maps)
        </a>
      </div>
    </div>
  </div>
</div>

<!-- Loader -->
<ng-template #loading>
  <div class="h-screen flex items-center justify-center bg-gray-50">
    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
  </div>
</ng-template>

<!-- 🟡 MODAL EDIT PLACE (ADMIN) -->
<div *ngIf="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
  <div class="bg-white w-full max-w-xl mx-4 rounded-2xl shadow-xl flex flex-col max-h-[90vh]">
    <div class="px-6 py-4 border-b flex items-center justify-between">
      <h2 class="text-lg font-semibold text-gray-900">
        Modifier cette place
      </h2>
      <button type="button"
              (click)="closeEditModal()"
              class="text-gray-400 hover:text-gray-600">
        ✕
      </button>
    </div>

    <form class="px-6 py-4 space-y-4 overflow-y-auto" *ngIf="editingPlace as form">
      <!-- Nom -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Nom</label>
        <input
          [(ngModel)]="form.name"
          name="name"
          type="text"
          class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
      </div>

      <!-- Description -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
        <textarea
          [(ngModel)]="form.description"
          name="description"
          rows="3"
          class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"></textarea>
      </div>

      <!-- Lat / Lng -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Latitude</label>
          <input
            [(ngModel)]="form.latitude"
            name="latitude"
            type="number"
            step="0.000001"
            class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Longitude</label>
          <input
            [(ngModel)]="form.longitude"
            name="longitude"
            type="number"
            step="0.000001"
            class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
        </div>
      </div>

      <!-- Catégories -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Catégories</label>
        <div class="flex flex-wrap gap-2">
          <label *ngFor="let cat of availableCategories"
                 class="inline-flex items-center gap-2 text-xs bg-gray-100 px-3 py-1 rounded-full cursor-pointer">
            <input
              type="checkbox"
              [checked]="form.categories?.includes(cat)"
              (change)="toggleCategory(cat, $event)"
              class="rounded border-gray-300">
            <span>{{ cat }}</span>
          </label>
        </div>
      </div>

      <!-- Images existantes -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Images existantes</label>
        <div *ngIf="form.images && form.images.length > 0; else noImages" class="grid grid-cols-3 gap-3">
          <div *ngFor="let img of form.images" class="relative group">
            <img [src]="img"
                 class="w-full h-24 object-cover rounded-lg border border-gray-200">
            <button type="button"
                    (click)="removeExistingImage(img)"
                    class="absolute top-1 right-1 text-[10px] px-2 py-1 rounded-full bg-black/70 text-white opacity-0 group-hover:opacity-100 transition">
              Supprimer
            </button>
          </div>
        </div>
        <ng-template #noImages>
          <p class="text-xs text-gray-500 italic">Aucune image pour l’instant.</p>
        </ng-template>
      </div>

      <!-- Ajout de nouvelles images -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Ajouter des images</label>
        <input
          type="file"
          multiple
          (change)="onFilesSelected($event)"
          class="block w-full text-xs text-gray-600 file:mr-3 file:py-2 file:px-3 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-yellow-50 file:text-yellow-700 hover:file:bg-yellow-100">
        <div *ngIf="uploadingImages" class="mt-2 text-xs text-blue-600">
          Upload en cours...
        </div>
        <div *ngIf="uploadError" class="mt-2 text-xs text-red-600">
          {{ uploadError }}
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-2">
        <button type="button"
                (click)="closeEditModal()"
                class="px-4 py-2 text-sm rounded-lg border border-gray-300 hover:bg-gray-50">
          Annuler
        </button>
        <button type="button"
                (click)="savePlace()"
                class="px-4 py-2 text-sm rounded-lg bg-yellow-400 hover:bg-yellow-500 text-gray-900 font-semibold shadow">
          💾 Enregistrer
        </button>
      </div>
    </form>
  </div>
</div>
EOF

echo "✅ Patch terminé : édition complète de la place + gestion des images pour admin."
