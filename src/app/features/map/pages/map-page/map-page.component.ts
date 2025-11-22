import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import { Router, RouterModule } from '@angular/router'; // Ajout RouterModule
import * as L from 'leaflet';
import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-map-page',
  standalone: true,
  imports: [CommonModule, LeafletModule, RouterModule], // Ajout RouterModule ici
  templateUrl: './map-page.component.html',
  styleUrls: ['./map-page.component.css']
})
export class MapPageComponent implements OnInit, OnDestroy {
  options: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18,
        attribution: '© OpenStreetMap contributors'
      })
    ],
    zoom: 11,
    center: L.latLng(34.71, 11.15)
  };

  places: Place[] = [];
  layers: L.Layer[] = [];
  private sub: Subscription = new Subscription();

  constructor(private placesService: PlacesService, private router: Router) {}

  ngOnInit(): void {
    this.sub = this.placesService.getApprovedPlaces().subscribe({
      next: (data) => {
        this.places = data;
        this.updateMarkers();
      },
      error: (err) => console.error('Erreur chargement lieux:', err)
    });
  }

  ngOnDestroy(): void {
    this.sub.unsubscribe();
  }

  updateMarkers() {
    this.layers = this.places.map(place => {
      const marker = L.marker([place.latitude, place.longitude], {
        icon: L.icon({
          iconSize: [25, 41],
          iconAnchor: [13, 41],
          iconUrl: 'assets/marker-icon.png',
          shadowUrl: 'assets/marker-shadow.png'
        })
      });

      marker.bindPopup(`
        <div class="text-center">
          <h3 class="font-bold text-lg">${place.name}</h3>
          <button id="btn-${place.id}" class="mt-2 bg-blue-600 text-white px-3 py-1 rounded text-xs hover:bg-blue-700 transition">
            Voir détails
          </button>
        </div>
      `);

      marker.on('popupopen', () => {
        const btn = document.getElementById(`btn-${place.id}`);
        if (btn) {
          btn.addEventListener('click', () => {
            this.router.navigate(['/place', place.id]);
          });
        }
      });

      return marker;
    });
  }

  // Correction de la signature : map est optionnel ou typé L.Map
  onMapReady(map: L.Map) {
    // Correction des icônes par défaut Leaflet
    const iconRetinaUrl = 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon-2x.png';
    const iconUrl = 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png';
    const shadowUrl = 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png';
    
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
}
