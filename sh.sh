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
backup "src/app/core/models/place.model.ts"
backup "src/app/features/admin/pages/add-place/add-place.component.ts"
backup "src/app/features/admin/pages/add-place/add-place.component.html"
backup "src/app/features/map/pages/place-detail/place-detail.component.ts"
backup "src/app/features/map/pages/place-detail/place-detail.component.html"

############################################
# 1) place.model.ts : ajout videos?: string[]
############################################
cat > src/app/core/models/place.model.ts <<'EOF'
export interface Place {
  id?: string;
  name: string;
  description: string;
  latitude: number;
  longitude: number;
  categories: string[];
  images: string[]; // URLs des images stockées (ex: Supabase)
  videos?: string[]; // URLs des vidéos stockées (Supabase)
  status: 'pending' | 'approved' | 'rejected';
  createdBy: string; // UID de l'utilisateur
  createdAt: Date | any; // compatibilité Timestamp Firestore
  updatedAt?: Date | any;
}
EOF

###########################################################
# 2) AddPlaceComponent TS : images + vidéos + catégories
###########################################################
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
    status: 'pending',
    images: [],
    videos: []
  };

  // Liste de catégories enrichie
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
    // Fix Leaflet icons
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
    if (!input.files || input.files.length === 0) {
      return;
    }

    const files = Array.from(input.files);
    this.uploadingImages = true;
    this.errorMessage = '';

    try {
      if (!this.model.images) {
        this.model.images = [];
      }

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `images/${fileName}`;
        const url = await this.imageService.uploadImage(file, path);
        if (url) {
          this.model.images.push(url);
        }
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
    if (!input.files || input.files.length === 0) {
      return;
    }

    const files = Array.from(input.files);
    this.uploadingVideos = true;
    this.errorMessage = '';

    try {
      if (!this.model.videos) {
        this.model.videos = [];
      }

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `videos/${fileName}`;
        const url = await this.imageService.uploadImage(file, path);
        if (url) {
          this.model.videos.push(url);
        }
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

  // Supprimer une image de la liste locale
  removeImage(url: string) {
    if (!this.model.images) return;
    this.model.images = this.model.images.filter(img => img !== url);
  }

  // Supprimer une vidéo de la liste locale
  removeVideo(url: string) {
    if (!this.model.videos) return;
    this.model.videos = this.model.videos.filter(v => v !== url);
  }

  // Soumission du formulaire
  async onSubmit(form: NgForm) {
    if (form.invalid || this.isSubmitting) {
      return;
    }

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

      const placeData: Place = {
        name: this.model.name!.trim(),
        description: this.model.description!.trim(),
        latitude: this.model.latitude!,
        longitude: this.model.longitude!,
        categories: this.model.categories || [],
        images: this.model.images || [],
        videos: this.model.videos || [],
        status: 'pending',
        createdBy: (user as any).uid || (user as any).id || 'unknown',
        createdAt: new Date()
      };

      await this.placesService.addPlace(placeData);

      this.successMessage = 'Lieu ajouté avec succès !';
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

#######################################################################
# 3) AddPlaceComponent HTML : upload + preview images & vidéos
#######################################################################
cat > src/app/features/admin/pages/add-place/add-place.component.html <<'EOF'
<div class="container mx-auto p-6 max-w-3xl">
  <div class="bg-white rounded-xl shadow-lg p-8">
    <h1 class="text-2xl font-bold text-blue-900 mb-6 border-b pb-2">
      Ajouter un nouveau lieu
    </h1>

    <!-- Messages -->
    <div *ngIf="errorMessage" class="mb-4 bg-red-50 text-red-600 p-3 rounded border border-red-100">
      {{ errorMessage }}
    </div>
    <div *ngIf="successMessage" class="mb-4 bg-green-50 text-green-600 p-3 rounded border border-green-100">
      {{ successMessage }}
    </div>

    <form #placeForm="ngForm" (ngSubmit)="onSubmit(placeForm)" class="space-y-6">
      <!-- Nom -->
      <div>
        <label class="block text-gray-700 font-medium mb-1">Nom du lieu *</label>
        <input
          type="text"
          [(ngModel)]="model.name"
          name="name"
          required
          class="w-full p-3 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 outline-none"
          placeholder="Ex: Restaurant La Sirène"
        />
      </div>

      <!-- Description -->
      <div>
        <label class="block text-gray-700 font-medium mb-1">Description *</label>
        <textarea
          [(ngModel)]="model.description"
          name="description"
          required
          rows="3"
          class="w-full p-3 border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 outline-none"
          placeholder="Décrivez ce lieu..."
        ></textarea>
      </div>

      <!-- Catégories -->
      <div>
        <label class="block text-gray-700 font-medium mb-2">Catégories</label>
        <p class="text-xs text-gray-500 mb-2">
          Sélectionnez une ou plusieurs catégories correspondant au lieu.
        </p>
        <div class="flex flex-wrap gap-2">
          <label
            *ngFor="let cat of categoriesList"
            class="flex items-center gap-2 bg-gray-50 px-3 py-2 rounded-full border cursor-pointer hover:bg-blue-50"
          >
            <input
              type="checkbox"
              [checked]="model.categories?.includes(cat)"
              (change)="toggleCategory(cat, $event)"
              class="rounded text-blue-600"
            />
            <span class="text-gray-700 text-xs md:text-sm">{{ cat }}</span>
          </label>
        </div>
      </div>

      <!-- Position (Carte) -->
      <div>
        <label class="block text-gray-700 font-medium mb-1">
          Position (Cliquez sur la carte) *
        </label>
        <p class="text-xs text-gray-500 mb-2">
          Lat:
          {{ model.latitude | number : '1.4-4' }},
          Lng:
          {{ model.longitude | number : '1.4-4' }}
        </p>

        <div class="h-64 w-full rounded overflow-hidden border border-gray-300 relative z-0">
          <div
            class="h-full w-full"
            leaflet
            [leafletOptions]="mapOptions"
            [leafletLayers]="mapLayers"
            (leafletMapReady)="onMapReady($event)"
          ></div>
        </div>
      </div>

      <!-- Images -->
      <div>
        <label class="block text-gray-700 font-medium mb-1">Photos du lieu</label>
        <input
          type="file"
          multiple
          accept="image/*"
          (change)="onImagesSelected($event)"
          class="block w-full text-sm text-gray-600
                 file:mr-4 file:py-2 file:px-4
                 file:rounded-full file:border-0
                 file:text-sm file:font-semibold
                 file:bg-blue-50 file:text-blue-700
                 hover:file:bg-blue-100"
        />

        <div *ngIf="uploadingImages" class="text-sm text-blue-600 mt-1">
          Téléchargement des images...
        </div>

        <!-- Prévisualisation images -->
        <div
          *ngIf="model.images && model.images.length > 0"
          class="mt-3 grid grid-cols-3 gap-3"
        >
          <div
            *ngFor="let img of model.images"
            class="relative group rounded-lg overflow-hidden border border-gray-200"
          >
            <img [src]="img" class="w-full h-24 object-cover" alt="Photo du lieu" />
            <button
              type="button"
              (click)="removeImage(img)"
              class="absolute top-1 right-1 text-[10px] px-2 py-1 rounded-full bg-black/70 text-white opacity-0 group-hover:opacity-100 transition"
            >
              ✕
            </button>
          </div>
        </div>
      </div>

      <!-- Vidéos -->
      <div>
        <label class="block text-gray-700 font-medium mb-1">Vidéos du lieu</label>
        <input
          type="file"
          multiple
          accept="video/*"
          (change)="onVideosSelected($event)"
          class="block w-full text-sm text-gray-600
                 file:mr-4 file:py-2 file:px-4
                 file:rounded-full file:border-0
                 file:text-sm file:font-semibold
                 file:bg-purple-50 file:text-purple-700
                 hover:file:bg-purple-100"
        />

        <div *ngIf="uploadingVideos" class="text-sm text-purple-600 mt-1">
          Téléchargement des vidéos...
        </div>

        <!-- Prévisualisation vidéos -->
        <div
          *ngIf="model.videos && model.videos.length > 0"
          class="mt-3 grid grid-cols-2 gap-3"
        >
          <div
            *ngFor="let vid of model.videos"
            class="relative group rounded-lg overflow-hidden border border-gray-200"
          >
            <video
              [src]="vid"
              class="w-full h-32 object-cover"
              controls
            ></video>
            <button
              type="button"
              (click)="removeVideo(vid)"
              class="absolute top-1 right-1 text-[10px] px-2 py-1 rounded-full bg-black/70 text-white opacity-0 group-hover:opacity-100 transition"
            >
              ✕
            </button>
          </div>
        </div>
      </div>

      <!-- Bouton Soumettre -->
      <div class="pt-4">
        <button
          type="submit"
          [disabled]="!placeForm.form.valid || isSubmitting || uploadingImages || uploadingVideos"
          class="w-full bg-blue-600 text-white font-bold py-3 rounded-lg shadow-md hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <span *ngIf="!isSubmitting">Ajouter le lieu</span>
          <span *ngIf="isSubmitting">Enregistrement...</span>
        </button>
      </div>
    </form>
  </div>
</div>
EOF

#################################################################################
# 4) PlaceDetailComponent TS : support images + vidéos (affichage + édition)
#################################################################################
cat > src/app/features/map/pages/place-detail/place-detail.component.ts <<'EOF'
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule, Router } from '@angular/router';
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
  private router = inject(Router);
  private placesService = inject(PlacesService);
  private authService = inject(AuthService);
  private supabaseImageService = inject(SupabaseImageService);

  place$: Observable<Place | undefined> = of(undefined);

  isAdmin = false;

  showEditModal = false;
  editingPlace: Place | null = null;

  availableCategories: string[] = [
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

  uploadingImages = false;
  uploadingVideos = false;
  uploadError: string | null = null;

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
    const iconRetinaUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png';
    const iconUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png';
    const shadowUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png';
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
    this.authService.user$.subscribe(user => {
      const roles = (user as any)?.roles;
      this.isAdmin = !!roles && Array.isArray(roles) && roles.includes('admin');
    });

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
    this.mapOptions = {
      ...this.mapOptions,
      center: L.latLng(place.latitude, place.longitude)
    };

    this.mapLayers = [
      L.marker([place.latitude, place.longitude]).bindPopup(place.name)
    ];
  }

  openEditModal(place: Place) {
    this.uploadError = null;
    this.editingPlace = {
      ...place,
      images: [...(place.images || [])],
      videos: [...(place.videos || [])],
      categories: [...(place.categories || [])]
    };
    this.showEditModal = true;
  }

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

  async onImagesSelected(event: Event) {
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
        const path = `images/${idPart}-${Date.now()}-${safeName}`;
        const url = await this.supabaseImageService.uploadImage(file, path);
        if (url) {
          newUrls.push(url);
        }
      }

      this.editingPlace = {
        ...this.editingPlace,
        images: [...(this.editingPlace.images || []), ...newUrls]
      };

      input.value = '';
    } catch (err) {
      console.error('Erreur upload images', err);
      this.uploadError = "Erreur lors de l'upload des images.";
    } finally {
      this.uploadingImages = false;
    }
  }

  async onVideosSelected(event: Event) {
    if (!this.editingPlace) return;
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const files = Array.from(input.files);
    this.uploadingVideos = true;
    this.uploadError = null;

    try {
      const newUrls: string[] = [];
      for (const file of files) {
        const safeName = file.name.replace(/\s+/g, '-').toLowerCase();
        const idPart = this.editingPlace.id || 'temp';
        const path = `videos/${idPart}-${Date.now()}-${safeName}`;
        const url = await this.supabaseImageService.uploadImage(file, path);
        if (url) {
          newUrls.push(url);
        }
      }

      this.editingPlace = {
        ...this.editingPlace,
        videos: [...(this.editingPlace.videos || []), ...newUrls]
      };

      input.value = '';
    } catch (err) {
      console.error('Erreur upload vidéos', err);
      this.uploadError = "Erreur lors de l'upload des vidéos.";
    } finally {
      this.uploadingVideos = false;
    }
  }

  removeExistingImage(url: string) {
    if (!this.editingPlace) return;
    this.editingPlace = {
      ...this.editingPlace,
      images: (this.editingPlace.images || []).filter(img => img !== url)
    };
  }

  removeExistingVideo(url: string) {
    if (!this.editingPlace) return;
    this.editingPlace = {
      ...this.editingPlace,
      videos: (this.editingPlace.videos || []).filter(v => v !== url)
    };
  }

  closeEditModal() {
    this.showEditModal = false;
    this.editingPlace = null;
    this.uploadError = null;
    this.uploadingImages = false;
    this.uploadingVideos = false;
  }

  async savePlace() {
    if (!this.editingPlace || !this.editingPlace.id) return;

    const id = this.editingPlace.id;
    const payload: Partial<Place> = {
      name: this.editingPlace.name,
      description: this.editingPlace.description,
      latitude: this.editingPlace.latitude,
      longitude: this.editingPlace.longitude,
      categories: this.editingPlace.categories || [],
      images: this.editingPlace.images || [],
      videos: this.editingPlace.videos || [],
      updatedAt: new Date()
    };

    try {
      await this.placesService.updatePlace(id, payload);
      this.closeEditModal();

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

  async onDeletePlace(place: Place) {
    if (!place.id) return;
    const ok = window.confirm(
      'Êtes-vous sûr de vouloir supprimer définitivement cette place ?'
    );
    if (!ok) return;

    try {
      await this.placesService.deletePlace(place.id);
      this.router.navigate(['/']);
    } catch (err) {
      console.error('Erreur suppression place', err);
      alert("Erreur lors de la suppression de la place.");
    }
  }
}
EOF

#################################################################################
# 5) PlaceDetailComponent HTML : affiche images + vidéos + modale d’édition
#################################################################################
cat > src/app/features/map/pages/place-detail/place-detail.component.html <<'EOF'
<div class="min-h-screen bg-gray-50 pb-12" *ngIf="place$ | async as place; else loading">
  <!-- Hero -->
  <div class="relative h-64 md:h-96 w-full bg-gray-800 overflow-hidden">
    <img
      *ngIf="place.images && place.images.length > 0"
      [src]="place.images[0]"
      class="w-full h-full object-cover opacity-70"
      alt="{{ place.name }}"
    />

    <div
      *ngIf="!place.images || place.images.length === 0"
      class="absolute inset-0 bg-gradient-to-r from-blue-900 to-blue-700 opacity-80"
    ></div>

    <!-- Titre + boutons -->
    <div class="absolute bottom-0 left-0 w-full p-6 md:p-10 bg-gradient-to-t from-black/80 to-transparent">
      <div class="container mx-auto">
        <div class="flex flex-wrap gap-2 mb-3">
          <span
            *ngFor="let cat of place.categories"
            class="bg-yellow-400 text-blue-900 text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wide"
          >
            {{ cat }}
          </span>
        </div>

        <div class="flex flex-col md:flex-row md:items-center gap-3">
          <h1 class="text-3xl md:text-5xl font-bold text-white drop-shadow-md">
            {{ place.name }}
          </h1>

          <div class="flex items-center gap-2 md:ml-auto" *ngIf="isAdmin">
            <button
              type="button"
              (click)="openEditModal(place)"
              class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-yellow-400 text-gray-900 text-xs md:text-sm font-semibold shadow-lg hover:bg-yellow-300 transition"
            >
              ✏️ Modifier
            </button>

            <button
              type="button"
              (click)="onDeletePlace(place)"
              class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-red-600 text-white text-xs md:text-sm font-semibold shadow-lg hover:bg-red-500 transition"
            >
              🗑️ Supprimer
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Bouton retour -->
    <a
      routerLink="/"
      class="absolute top-4 left-4 bg-white/10 hover:bg-white/20 border border-white/40 backdrop-blur text-white p-2 rounded-full transition"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="h-6 w-6"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M10 19l-7-7m0 0l7-7m-7 7h18"
        />
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

        <!-- Galerie photos -->
        <div *ngIf="place.images && place.images.length > 1" class="bg-white rounded-2xl shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-3">Galerie photos</h3>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
            <img
              *ngFor="let img of place.images"
              [src]="img"
              class="w-full h-32 md:h-40 object-cover rounded-xl border border-gray-200 hover:opacity-90 transition"
              alt="Photo de {{ place.name }}"
            />
          </div>
        </div>

        <!-- Vidéos -->
        <div *ngIf="place.videos && place.videos.length > 0" class="bg-white rounded-2xl shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-3">Vidéos</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <video
              *ngFor="let vid of place.videos"
              [src]="vid"
              controls
              class="w-full h-48 md:h-56 rounded-xl border border-gray-200 bg-black"
            ></video>
          </div>
        </div>
      </div>

      <!-- Colonne latérale -->
      <div class="space-y-6">
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div class="px-4 py-3 bg-blue-50 border-b border-blue-100">
            <h3 class="font-bold text-blue-900 text-sm">Localisation</h3>
          </div>
          <div class="h-64 w-full relative z-0">
            <div
              class="h-full w-full"
              leaflet
              [leafletOptions]="mapOptions"
              [leafletLayers]="mapLayers"
            ></div>
          </div>
          <div class="p-4 bg-gray-50 text-xs text-gray-600 flex flex-col gap-1">
            <div>
              <span class="font-semibold">Latitude :</span>
              {{ place.latitude | number : '1.4-4' }}
            </div>
            <div>
              <span class="font-semibold">Longitude :</span>
              {{ place.longitude | number : '1.4-4' }}
            </div>
          </div>
        </div>

        <!-- Google Maps -->
        <a
          class="block w-full bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium px-4 py-3 rounded-lg shadow flex items-center justify-center gap-2"
          [href]="'https://www.google.com/maps/search/?api=1&query=' + place.latitude + ',' + place.longitude"
          target="_blank"
          rel="noopener noreferrer"
        >
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

<!-- MODAL EDIT PLACE (ADMIN) -->
<div *ngIf="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
  <div class="bg-white w-full max-w-xl mx-4 rounded-2xl shadow-xl flex flex-col max-h-[90vh]">
    <div class="px-6 py-4 border-b flex items-center justify-between">
      <h2 class="text-lg font-semibold text-gray-900">Modifier cette place</h2>
      <button
        type="button"
        (click)="closeEditModal()"
        class="text-gray-400 hover:text-gray-600"
      >
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
          class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <!-- Description -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
        <textarea
          [(ngModel)]="form.description"
          name="description"
          rows="3"
          class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
        ></textarea>
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
            class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Longitude</label>
          <input
            [(ngModel)]="form.longitude"
            name="longitude"
            type="number"
            step="0.000001"
            class="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <!-- Catégories -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Catégories</label>
        <div class="flex flex-wrap gap-2">
          <label
            *ngFor="let cat of availableCategories"
            class="inline-flex items-center gap-2 text-xs bg-gray-100 px-3 py-1 rounded-full cursor-pointer"
          >
            <input
              type="checkbox"
              [checked]="form.categories?.includes(cat)"
              (change)="toggleCategory(cat, $event)"
              class="rounded border-gray-300"
            />
            <span>{{ cat }}</span>
          </label>
        </div>
      </div>

      <!-- Images existantes -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Images existantes</label>
        <div *ngIf="form.images && form.images.length > 0; else noImages" class="grid grid-cols-3 gap-3">
          <div *ngFor="let img of form.images" class="relative group">
            <img
              [src]="img"
              class="w-full h-24 object-cover rounded-lg border border-gray-200"
            />
            <button
              type="button"
              (click)="removeExistingImage(img)"
              class="absolute top-1 right-1 text-[10px] px-2 py-1 rounded-full bg-black/70 text-white opacity-0 group-hover:opacity-100 transition"
            >
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
          accept="image/*"
          (change)="onImagesSelected($event)"
          class="block w-full text-xs text-gray-600 file:mr-3 file:py-2 file:px-3 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-yellow-50 file:text-yellow-700 hover:file:bg-yellow-100"
        />
        <div *ngIf="uploadingImages" class="mt-2 text-xs text-blue-600">
          Upload des images en cours...
        </div>
      </div>

      <!-- Vidéos existantes -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Vidéos existantes</label>
        <div *ngIf="form.videos && form.videos.length > 0; else noVideos" class="grid grid-cols-2 gap-3">
          <div *ngFor="let vid of form.videos" class="relative group">
            <video
              [src]="vid"
              class="w-full h-24 object-cover rounded-lg border border-gray-200 bg-black"
              controls
            ></video>
            <button
              type="button"
              (click)="removeExistingVideo(vid)"
              class="absolute top-1 right-1 text-[10px] px-2 py-1 rounded-full bg-black/70 text-white opacity-0 group-hover:opacity-100 transition"
            >
              Supprimer
            </button>
          </div>
        </div>
        <ng-template #noVideos>
          <p class="text-xs text-gray-500 italic">Aucune vidéo pour l’instant.</p>
        </ng-template>
      </div>

      <!-- Ajout de nouvelles vidéos -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Ajouter des vidéos</label>
        <input
          type="file"
          multiple
          accept="video/*"
          (change)="onVideosSelected($event)"
          class="block w-full text-xs text-gray-600 file:mr-3 file:py-2 file:px-3 file:rounded-full file:border-0 file:text-xs file:font-semibold file:bg-purple-50 file:text-purple-700 hover:file:bg-purple-100"
        />
        <div *ngIf="uploadingVideos" class="mt-2 text-xs text-purple-600">
          Upload des vidéos en cours...
        </div>
        <div *ngIf="uploadError" class="mt-2 text-xs text-red-600">
          {{ uploadError }}
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-2">
        <button
          type="button"
          (click)="closeEditModal()"
          class="px-4 py-2 text-sm rounded-lg border border-gray-300 hover:bg-gray-50"
        >
          Annuler
        </button>
        <button
          type="button"
          (click)="savePlace()"
          class="px-4 py-2 text-sm rounded-lg bg-yellow-400 hover:bg-yellow-500 text-gray-900 font-semibold shadow"
        >
          💾 Enregistrer
        </button>
      </div>
    </form>
  </div>
</div>
EOF

echo "✅ Patch terminé : les places gèrent maintenant IMAGES + VIDÉOS (ajout + édition + affichage)."
