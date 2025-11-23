import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import { FormsModule } from '@angular/forms';
import * as L from 'leaflet';
import { Observable, of } from 'rxjs';
import { switchMap, tap } from 'rxjs/operators';
import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';
import { AuthService } from '../../../../core/services/auth.service';

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

  place$: Observable<Place | undefined> = of(undefined);

  // 🔐 visible uniquement si ADMIN
  isAdmin = false;

  // 🟡 Modal d'édition
  showEditModal = false;
  editingPlace: Place | null = null;

  // Quelques catégories proposées (tu peux adapter)
  availableCategories: string[] = [
    'café',
    'restaurant',
    'parc',
    'plage',
    'monument',
    'hébergement'
  ];

  // Options de carte
  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 18 })
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
      this.isAdmin = !!user && Array.isArray(user.roles) && user.roles.includes('admin');
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
    this.editingPlace = { ...place };
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

  closeEditModal() {
    this.showEditModal = false;
    this.editingPlace = null;
  }

  // Sauvegarde Firestore + refresh des données
  async savePlace() {
    if (!this.editingPlace || !this.editingPlace.id) {
      return;
    }

    const id = this.editingPlace.id;
    const payload: Partial<Place> = {
      ...this.editingPlace,
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
