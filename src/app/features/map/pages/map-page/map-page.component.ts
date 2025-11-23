import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import { Router, RouterModule } from '@angular/router';
import * as L from 'leaflet';
import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-map-page',
  standalone: true,
  imports: [CommonModule, LeafletModule, RouterModule],
  templateUrl: './map-page.component.html',
  styleUrls: ['./map-page.component.css']
})
export class MapPageComponent implements OnInit, OnDestroy {
  // Centré sur Kerkennah avec un zoom adapté
  options: L.MapOptions = {
    layers: [L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 18 })],
    zoom: 11,
    center: L.latLng(34.71, 11.15)
  };

  places: Place[] = [];
  layers: L.Layer[] = [];
  private sub: Subscription = new Subscription();

  constructor(private placesService: PlacesService, private router: Router) {}

  ngOnInit(): void {
    this.sub = this.placesService.getApprovedPlaces().subscribe(data => {
      this.places = data;
      this.updateMarkers();
    });
  }

  ngOnDestroy(): void {
    this.sub.unsubscribe();
  }

  /**
   * Détermine l'icône et la couleur en fonction des catégories
   */
  getIcon(categories: string[]) {
    let type = 'default';
    let emoji = '📍';
    
    // On convertit tout en minuscule pour la recherche insensible à la casse
    const c = categories.map(x => x.toLowerCase()).join(' ');
    
    // LOGIQUE DE PRIORITÉ
    
    // 1. Santé & Urgences
    if (c.includes('pharmacie') || c.includes('hôpital') || c.includes('santé') || c.includes('urgences')) {
      type = 'sante'; emoji = '🏥';
    }
    // 2. Éducation & Administration
    else if (c.includes('école') || c.includes('lycée') || c.includes('collège') || c.includes('poste') || c.includes('mairie') || c.includes('ville')) {
      type = 'ecole'; emoji = '🎓'; // ou 🏢 pour admin
      if (c.includes('poste') || c.includes('mairie')) emoji = '🏢';
    }
    // 3. Restauration
    else if (c.includes('restaurant') || c.includes('snack') || c.includes('pizzeria') || c.includes('fast food')) {
      type = 'restaurant'; emoji = '🍴';
    }
    else if (c.includes('café') || c.includes('salon de thé') || c.includes('buvette')) {
      type = 'cafe'; emoji = '☕';
    }
    // 4. Hébergement
    else if (c.includes('hôtel') || c.includes('hotel') || c.includes('résidence') || c.includes('maison d\'hôtes')) {
      type = 'hotel'; emoji = '🏨';
    }
    // 5. Loisirs & Nature
    else if (c.includes('plage') || c.includes('baignade') || c.includes('mer')) {
      type = 'plage'; emoji = '🏖️';
    }
    else if (c.includes('port') || c.includes('pêche') || c.includes('bateau')) {
      type = 'port'; emoji = '⚓';
    }
    // 6. Culture & Religion
    else if (c.includes('mosquée') || c.includes('zaouia')) {
      type = 'culture'; emoji = '🕌';
    }
    else if (c.includes('histoire') || c.includes('musée') || c.includes('ruine') || c.includes('site')) {
      type = 'culture'; emoji = '🏛️';
    }
    // 7. Commerce
    else if (c.includes('commerce') || c.includes('épicerie') || c.includes('magasin') || c.includes('marché')) {
      type = 'ecole'; emoji = '🛒'; // On réutilise le bleu ou on crée une classe commerce
    }

    return L.divIcon({
      className: 'custom-div-icon',
      html: `<div class="marker-pin ${type}"><span>${emoji}</span></div>`,
      iconSize: [42, 42],
      iconAnchor: [21, 42],
      popupAnchor: [0, -45]
    });
  }

  updateMarkers() {
    this.layers = this.places.map(p => {
      const m = L.marker([p.latitude, p.longitude], { 
        icon: this.getIcon(p.categories || []) 
      });
      
      // Gestion image (si tableau vide ou erreur, image par défaut)
      const img = (p.images && p.images.length > 0) 
        ? p.images[0] 
        : 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/300px-No_image_available.svg.png';
      
      // Popup HTML
      m.bindPopup(`
        <div class="text-center font-sans">
          <h3 class="font-bold text-base text-gray-800 mb-2 truncate">${p.name}</h3>
          <div class="relative">
             <img src="${img}" class="popup-image" onerror="this.src='https://via.placeholder.com/300?text=Image+Indisponible'">
             <span class="absolute bottom-3 right-1 bg-white/80 px-1 rounded text-[10px] font-bold text-gray-600">
               ${p.categories[0] || 'Lieu'}
             </span>
          </div>
          <button id="btn-${p.id}" 
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-full text-xs font-bold w-full transition shadow-sm flex items-center justify-center gap-1">
            <span>👁️</span> Voir Détails
          </button>
        </div>
      `);
      
      m.on('popupopen', () => {
        const btn = document.getElementById(`btn-${p.id}`);
        if (btn) btn.addEventListener('click', () => this.router.navigate(['/place', p.id]));
      });
      
      return m;
    });
  }

  onMapReady(map: L.Map) {
    // Optionnel: Ajustements au chargement de la carte
  }
}
