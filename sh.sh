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

echo "📦 Backup des fichiers existants..."
backup "src/app/features/admin/pages/add-place/add-place.component.ts"
backup "src/app/features/admin/pages/add-place/add-place.component.html"

############################################
# 1) TS : AddPlaceComponent (images + catégories)
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
  // Modèle du formulaire
  model: Partial<Place> = {
    name: '',
    description: '',
    latitude: 34.71,
    longitude: 11.15,
    categories: [],
    status: 'pending',
    images: []
  };

  // ✅ Liste de catégories riche
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
  uploadingImage = false;
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

  private marker: L.Marker | null = null;

  constructor(
    private placesService: PlacesService,
    private imageService: SupabaseImageService,
    private auth: AuthService,
    private router: Router
  ) {
    // Fix des icônes Leaflet
    const iconRetinaUrl =
      'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png';
    const iconUrl =
      'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png';
    const shadowUrl =
      'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png';

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
    this.updateMarker(this.model.latitude!, this.model.longitude!);
  }

  onMapReady(map: L.Map) {
    map.on('click', (e: L.LeafletMouseEvent) => {
      this.model.latitude = e.latlng.lat;
      this.model.longitude = e.latlng.lng;
      this.updateMarker(e.latlng.lat, e.latlng.lng);
    });
  }

  private updateMarker(lat: number, lng: number) {
    if (this.marker) {
      this.marker.setLatLng([lat, lng]);
    } else {
      this.marker = L.marker([lat, lng]);
    }
  }

  get mapLayers(): L.Layer[] {
    return this.marker ? [this.marker] : [];
  }

  // ✅ Gestion des catégories (checkbox)
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

  // ✅ Upload MULTIPLE images vers Supabase
  async onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) {
      return;
    }

    const files = Array.from(input.files);

    this.uploadingImage = true;
    this.errorMessage = '';

    try {
      if (!this.model.images) {
        this.model.images = [];
      }

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `places/${fileName}`;

        console.log('📤 Upload image:', path);
        const url = await this.imageService.uploadImage(file, path);
        if (url) {
          this.model.images.push(url);
        }
      }

      // reset input
      input.value = '';
    } catch (err: any) {
      console.error('Upload failed', err);
      this.errorMessage =
        "Erreur lors de l'upload des images : " +
        (err?.message || 'Vérifiez votre configuration Supabase');
    } finally {
      this.uploadingImage = false;
    }
  }

  // ✅ Supprimer une image du formulaire (ne supprime pas dans Supabase)
  removeImage(url: string) {
    if (!this.model.images) return;
    this.model.images = this.model.images.filter(img => img !== url);
  }

  // ✅ Soumission du formulaire
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
        images: []
      });
      this.model = {
        latitude: 34.71,
        longitude: 11.15,
        categories: [],
        images: [],
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
# 2) HTML : formulaire avec upload + preview
############################################
cat > src/app/features/admin/pages/add-place/add-place.component.html <<'EOF'
<div class="container mx-auto p-6 max-w-3xl">
  <div class="bg-white rounded-xl shadow-lg p-8">
    <h1 class="text-2xl font-bold text-blue-900 mb-6 border-b pb-2">
      Ajouter un nouveau lieu
    </h1>

    <!-- Messages -->
    <div
      *ngIf="errorMessage"
      class="mb-4 bg-red-50 text-red-600 p-3 rounded border border-red-100"
    >
      {{ errorMessage }}
    </div>
    <div
      *ngIf="successMessage"
      class="mb-4 bg-green-50 text-green-600 p-3 rounded border border-green-100"
    >
      {{ successMessage }}
    </div>

    <form
      #placeForm="ngForm"
      (ngSubmit)="onSubmit(placeForm)"
      class="space-y-6"
    >
      <!-- Nom -->
      <div>
        <label class="block text-gray-700 font-medium mb-1"
          >Nom du lieu *</label
        >
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
        <label class="block text-gray-700 font-medium mb-1"
          >Description *</label
        >
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

        <div
          class="h-64 w-full rounded overflow-hidden border border-gray-300 relative z-0"
        >
          <div
            class="h-full w-full"
            leaflet
            [leafletOptions]="mapOptions"
            [leafletLayers]="mapLayers"
            (leafletMapReady)="onMapReady($event)"
          >
          </div>
        </div>
      </div>

      <!-- Images -->
      <div>
        <label class="block text-gray-700 font-medium mb-1"
          >Photos du lieu</label
        >
        <input
          type="file"
          multiple
          accept="image/*"
          (change)="onFileSelected($event)"
          class="block w-full text-sm text-gray-600
                 file:mr-4 file:py-2 file:px-4
                 file:rounded-full file:border-0
                 file:text-sm file:font-semibold
                 file:bg-blue-50 file:text-blue-700
                 hover:file:bg-blue-100"
        />

        <div *ngIf="uploadingImage" class="text-sm text-blue-600 mt-1">
          Téléchargement en cours...
        </div>

        <!-- Prévisualisation -->
        <div
          *ngIf="model.images && model.images.length > 0"
          class="mt-3 grid grid-cols-3 gap-3"
        >
          <div
            *ngFor="let img of model.images"
            class="relative group rounded-lg overflow-hidden border border-gray-200"
          >
            <img
              [src]="img"
              class="w-full h-24 object-cover"
              alt="Photo du lieu"
            />
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

      <!-- Bouton Soumettre -->
      <div class="pt-4">
        <button
          type="submit"
          [disabled]="!placeForm.form.valid || isSubmitting || uploadingImage"
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

echo "✅ Patch terminé : formulaire d'ajout mis à jour (upload multi-images + beaucoup de catégories)."
