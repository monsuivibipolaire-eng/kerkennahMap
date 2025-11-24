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

echo "📦 Backup des fichiers importants..."
backup "src/app/core/models/place.model.ts"
backup "src/app/core/services/places.service.ts"
backup "src/app/features/admin/pages/add-place/add-place.component.ts"
backup "src/app/features/admin/pages/admin-list/admin-list.component.ts"
backup "src/app/features/admin/pages/admin-list/admin-list.component.html"

############################################
# 1) Modèle Place : statut + vidéos optionnelles
############################################
cat > src/app/core/models/place.model.ts <<'EOF'
export interface Place {
  id?: string;
  name: string;
  description: string;
  latitude: number;
  longitude: number;
  categories: string[];
  images: string[];      // URLs des images (Supabase, etc.)
  videos?: string[];     // URLs des vidéos (optionnel)
  status: 'pending' | 'approved' | 'rejected';
  createdBy: string;     // UID de l'utilisateur
  createdAt: Date | any; // compatibilité Timestamp Firestore
  updatedAt?: Date | any;
}
EOF

############################################
# 2) Service PlacesService : moderation
############################################
cat > src/app/core/services/places.service.ts <<'EOF'
import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  collectionData,
  doc,
  docData,
  addDoc,
  query,
  where,
  updateDoc,
  deleteDoc
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Place } from '../models/place.model';

@Injectable({
  providedIn: 'root'
})
export class PlacesService {
  private firestore: Firestore = inject(Firestore);

  constructor() {}

  // 🔵 Lieux publiés (status = 'approved')
  getApprovedPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'approved'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // 📍 Un lieu par son ID
  getPlaceById(id: string): Observable<Place | undefined> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return docData(placeDocRef, { idField: 'id' }) as Observable<Place>;
  }

  // ➕ Ajouter un lieu
  addPlace(place: Place): Promise<any> {
    const placesRef = collection(this.firestore, 'places');
    return addDoc(placesRef, place);
  }

  // ✏️ Mise à jour générique
  updatePlace(id: string, data: Partial<Place>): Promise<void> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return updateDoc(placeDocRef, data as any);
  }

  // 🟥 Supprimer un lieu
  deletePlace(id: string): Promise<void> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return deleteDoc(placeDocRef);
  }

  // 🕒 Lieux en attente de validation
  getPendingPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'pending'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // ✅ Valider / approuver un lieu
  approvePlace(id: string): Promise<void> {
    return this.updatePlace(id, {
      status: 'approved',
      updatedAt: new Date()
    });
  }

  // ❌ Rejeter un lieu
  rejectPlace(id: string): Promise<void> {
    return this.updatePlace(id, {
      status: 'rejected',
      updatedAt: new Date()
    });
  }
}
EOF

############################################
# 3) AddPlaceComponent : status selon rôle
############################################
cat > src/app/features/admin/pages/add-place/add-place.component.ts <<'EOF'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import * as L from 'leaflet';
import { Router } from '@angular/router';
import { PlacesService } from '../../../../core/services/places.service';
import { SupabaseImageService } from '../../../../core/services/supabase-image.service';
import { AuthService } from '../../../../core/services/auth.service';
import { Place } from '../../../../core/models/place.model';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-add-place',
  standalone: true,
  imports: [CommonModule, FormsModule, LeafletModule],
  templateUrl: './add-place.component.html',
  styleUrls: ['./add-place.component.css']
})
export class AddPlaceComponent implements OnInit {
  // Modèle de base du formulaire
  model: Partial<Place> = {
    name: '',
    description: '',
    latitude: 34.71,
    longitude: 11.15,
    categories: [],
    images: [],
    videos: [],
    status: 'pending'
  };

  categoriesList: string[] = [
    'Restaurant',
    'Fruits de mer',
    'Café',
    'Fast-food',
    'Pizzeria',
    'Boulangerie',
    'Glacier',
    'Bar',
    'Hôtel',
    'Maison d’hôtes',
    'Camping',
    'Plage',
    'Parc',
    'Jardin',
    'Randonnée',
    'Musée',
    'Monument',
    'Site historique',
    'Site archéologique',
    'Centre commercial',
    'Marché',
    'Souk',
    'Commerce',
    'Spa',
    'Bien-être',
    'Activités nautiques',
    'Pêche',
    'Famille',
    'Romantique',
    'Vue panoramique'
  ];

  isSubmitting = false;
  uploadingImages = false;
  uploadingVideos = false;
  errorMessage = '';
  successMessage = '';

  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18
      })
    ],
    zoom: 10,
    center: L.latLng(34.71, 11.15)
  };

  marker: L.Marker | null = null;

  constructor(
    private placesService: PlacesService,
    private imageService: SupabaseImageService,
    private auth: AuthService,
    private router: Router
  ) {
    const iconRetinaUrl =
      'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png';
    const iconUrl =
      'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png';
    const shadowUrl =
      'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png';

    (L.Marker.prototype as any).options.icon = L.icon({
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
    this.updateMarker(this.model.latitude!, this.model.longitude!);
  }

  onMapReady(map: L.Map) {
    map.on('click', (e: L.LeafletMouseEvent) => {
      this.model.latitude = e.latlng.lat;
      this.model.longitude = e.latlng.lng;
      this.updateMarker(e.latlng.lat, e.latlng.lng);
    });
  }

  updateMarker(lat: number, lng: number) {
    if (this.marker) {
      this.marker.setLatLng([lat, lng]);
    } else {
      this.marker = L.marker([lat, lng]);
    }
  }

  get mapLayers(): L.Layer[] {
    return this.marker ? [this.marker] : [];
  }

  // Catégories (checkbox)
  toggleCategory(cat: string, event: Event) {
    const input = event.target as HTMLInputElement;
    const checked = input.checked;

    if (!this.model.categories) {
      this.model.categories = [];
    }

    if (checked) {
      if (!this.model.categories.includes(cat)) {
        this.model.categories.push(cat);
      }
    } else {
      this.model.categories = this.model.categories.filter(c => c !== cat);
    }
  }

  // Upload d'IMAGES
  async onImagesSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const files = Array.from(input.files);
    this.uploadingImages = true;
    this.errorMessage = '';

    try {
      if (!this.model.images) this.model.images = [];

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `images/${fileName}`;
        const url = await this.imageService.uploadImage(file, path);
        if (url) this.model.images.push(url);
      }

      input.value = '';
    } catch (err: any) {
      console.error('Upload images failed', err);
      this.errorMessage =
        "Erreur lors de l'upload des images : " +
        (err?.message || 'Vérifiez votre configuration Supabase');
    } finally {
      this.uploadingImages = false;
    }
  }

  // Upload de VIDEOS
  async onVideosSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const files = Array.from(input.files);
    this.uploadingVideos = true;
    this.errorMessage = '';

    try {
      if (!this.model.videos) this.model.videos = [];

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `videos/${fileName}`;
        const url = await this.imageService.uploadImage(file, path);
        if (url) this.model.videos.push(url);
      }

      input.value = '';
    } catch (err: any) {
      console.error('Upload videos failed', err);
      this.errorMessage =
        "Erreur lors de l'upload des vidéos : " +
        (err?.message || 'Vérifiez votre configuration Supabase');
    } finally {
      this.uploadingVideos = false;
    }
  }

  removeImage(url: string) {
    if (!this.model.images) return;
    this.model.images = this.model.images.filter(i => i !== url);
  }

  removeVideo(url: string) {
    if (!this.model.videos) return;
    this.model.videos = this.model.videos.filter(v => v !== url);
  }

  // Soumission du formulaire
  async onSubmit(form: NgForm) {
    if (form.invalid || this.isSubmitting) return;

    this.isSubmitting = true;
    this.errorMessage = '';
    this.successMessage = '';

    try {
      const user = await firstValueFrom(this.auth.user$);
      if (!user) {
        this.errorMessage = 'Vous devez être connecté.';
        this.isSubmitting = false;
        return;
      }

      const roles = (user as any).roles || [];
      const isAdmin =
        Array.isArray(roles) && roles.includes('admin');

      // ✅ Si admin -> approved, sinon -> pending
      const status: 'pending' | 'approved' | 'rejected' =
        isAdmin ? 'approved' : 'pending';

      const placeData: Place = {
        name: this.model.name!.trim(),
        description: this.model.description!.trim(),
        latitude: this.model.latitude!,
        longitude: this.model.longitude!,
        categories: this.model.categories || [],
        images: this.model.images || [],
        videos: this.model.videos || [],
        status,
        createdBy: (user as any).uid || (user as any).id || 'unknown',
        createdAt: new Date()
      };

      await this.placesService.addPlace(placeData);

      this.successMessage = isAdmin
        ? 'Lieu ajouté et publié avec succès !'
        : 'Lieu ajouté ! En attente de validation par un administrateur.';

      form.resetForm({
        latitude: 34.71,
        longitude: 11.15,
        categories: [],
        images: [],
        videos: []
      });
      this.model = {
        latitude: 34.71,
        longitude: 11.15,
        categories: [],
        images: [],
        videos: [],
        status: 'pending'
      };
      this.updateMarker(34.71, 11.15);

      setTimeout(() => this.router.navigate(['/']), 1500);
    } catch (err) {
      console.error(err);
      this.errorMessage = "Erreur lors de l'enregistrement.";
    } finally {
      this.isSubmitting = false;
    }
  }
}
EOF

############################################
# 4) AdminListComponent TS : modération des lieux en attente
############################################
cat > src/app/features/admin/pages/admin-list/admin-list.component.ts <<'EOF'
import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-admin-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './admin-list.component.html',
  styles: [`
    .card { @apply bg-white rounded-lg shadow p-6 mb-4; }
    .btn { @apply px-3 py-2 rounded text-sm font-semibold transition; }
    .btn-approve { @apply bg-green-600 text-white hover:bg-green-700; }
    .btn-reject { @apply bg-red-600 text-white hover:bg-red-700; }
    .badge { @apply inline-block text-xs px-2 py-1 rounded-full; }
  `]
})
export class AdminListComponent {
  private placesService = inject(PlacesService);

  pendingPlaces$: Observable<Place[]> =
    this.placesService.getPendingPlaces();

  isProcessingId: string | null = null;
  message = '';

  async approve(place: Place) {
    if (!place.id) return;
    this.isProcessingId = place.id;
    this.message = '';

    try {
      await this.placesService.approvePlace(place.id);
      this.message = `✅ Lieu "${place.name}" approuvé.`;
    } catch (err) {
      console.error(err);
      this.message = `❌ Erreur lors de la validation de "${place.name}".`;
    } finally {
      this.isProcessingId = null;
    }
  }

  async reject(place: Place) {
    if (!place.id) return;
    const confirmReject = window.confirm(
      `Êtes-vous sûr de vouloir rejeter le lieu "${place.name}" ?`
    );
    if (!confirmReject) return;

    this.isProcessingId = place.id;
    this.message = '';

    try {
      await this.placesService.rejectPlace(place.id);
      this.message = `✅ Lieu "${place.name}" rejeté.`;
    } catch (err) {
      console.error(err);
      this.message = `❌ Erreur lors du rejet de "${place.name}".`;
    } finally {
      this.isProcessingId = null;
    }
  }
}
EOF

############################################
# 5) AdminListComponent HTML : liste de modération
############################################
cat > src/app/features/admin/pages/admin-list/admin-list.component.html <<'EOF'
<div class="container mx-auto p-6">
  <h1 class="text-3xl font-bold text-blue-900 mb-6">
    Administration – Modération des lieux
  </h1>

  <div
    *ngIf="message"
    class="mb-4 p-3 rounded border text-sm"
    [ngClass]="{
      'bg-green-50 text-green-700 border-green-200': message.startsWith('✅'),
      'bg-red-50 text-red-700 border-red-200': message.startsWith('❌')
    }"
  >
    {{ message }}
  </div>

  <ng-container *ngIf="pendingPlaces$ | async as pending; else loading">
    <div *ngIf="pending.length === 0" class="text-gray-500 italic">
      Aucun lieu en attente de validation pour le moment.
    </div>

    <div *ngFor="let place of pending" class="card">
      <div class="flex flex-col md:flex-row md:items-start gap-4">
        <div class="flex-1">
          <div class="flex items-center gap-2 mb-1">
            <h2 class="text-lg font-semibold text-gray-900">
              {{ place.name }}
            </h2>
            <span class="badge bg-yellow-100 text-yellow-800 border border-yellow-200">
              En attente
            </span>
          </div>

          <p class="text-sm text-gray-600 mb-2">
            {{ place.description || 'Aucune description.' }}
          </p>

          <div class="flex flex-wrap gap-2 mb-2">
            <span
              *ngFor="let cat of place.categories"
              class="badge bg-blue-50 text-blue-700 border border-blue-100"
            >
              {{ cat }}
            </span>
          </div>

          <p class="text-xs text-gray-500">
            <span class="font-semibold">Position :</span>
            {{ place.latitude | number : '1.4-4' }},
            {{ place.longitude | number : '1.4-4' }}
          </p>

          <p class="text-xs text-gray-400 mt-1">
            Proposé par :
            <span class="font-mono">
              {{ place.createdBy || 'inconnu' }}
            </span>
          </p>
        </div>

        <div class="flex flex-col items-stretch gap-2 md:w-48">
          <a
            [routerLink]="['/place', place.id]"
            class="btn bg-blue-50 text-blue-700 border border-blue-200 hover:bg-blue-100 text-center"
          >
            👁 Voir la fiche
          </a>

          <button
            type="button"
            (click)="approve(place)"
            [disabled]="isProcessingId === place.id"
            class="btn btn-approve disabled:opacity-50 disabled:cursor-not-allowed"
          >
            ✅ Valider
          </button>

          <button
            type="button"
            (click)="reject(place)"
            [disabled]="isProcessingId === place.id"
            class="btn btn-reject disabled:opacity-50 disabled:cursor-not-allowed"
          >
            ❌ Rejeter
          </button>
        </div>
      </div>
    </div>
  </ng-container>

  <ng-template #loading>
    <div class="text-gray-500 italic">Chargement des lieux en attente...</div>
  </ng-template>
</div>
EOF

echo "✅ Patch moderation appliqué :"
echo "  - Utilisateur normal : lieux en 'pending', non visibles sur la carte"
echo "  - Admin : lieux en 'approved' directement, visibles sur la carte"
echo "  - /admin/places : liste des lieux en attente avec actions de validation/rejet"
