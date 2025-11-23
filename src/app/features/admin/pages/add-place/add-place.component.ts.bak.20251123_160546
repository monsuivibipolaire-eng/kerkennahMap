import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import * as L from 'leaflet';
import { Router } from '@angular/router';
import { PlacesService } from '../../../../core/services/places.service';
import { SupabaseImageService } from '../../../../core/services/supabase-image.service';
import { AuthService } from '../../../../core/services/auth.service';
import { Place } from '../../../../core/models/place.model';
import { take } from 'rxjs/operators';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-add-place',
  standalone: true,
  imports: [CommonModule, FormsModule, LeafletModule],
  templateUrl: './add-place.component.html',
  styleUrls: ['./add-place.component.css']
})
export class AddPlaceComponent implements OnInit {
  model: Partial<Place> = {
    name: '', description: '', latitude: 34.71, longitude: 11.15,
    categories: [], status: 'pending', images: []
  };
  
  categoriesList = ['Restaurant', 'Café', 'Plage', 'Hôtel', 'Histoire', 'Pêche', 'Commerce'];
  isSubmitting = false;
  uploadingImage = false;
  errorMessage = '';
  successMessage = '';
  
  mapOptions: L.MapOptions = {
    layers: [L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 18 })],
    zoom: 10, center: L.latLng(34.71, 11.15)
  };
  marker: L.Marker | null = null;

  constructor(
    private placesService: PlacesService,
    private imageService: SupabaseImageService,
    private auth: AuthService,
    private router: Router
  ) {
     // Fix Leaflet Icons
     const iconRetinaUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png';
     const iconUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png';
     const shadowUrl = 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png';
     L.Marker.prototype.options.icon = L.icon({
       iconRetinaUrl, iconUrl, shadowUrl,
       iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [1, -34], tooltipAnchor: [16, -28], shadowSize: [41, 41]
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
    if (this.marker) this.marker.setLatLng([lat, lng]);
    else this.marker = L.marker([lat, lng]);
  }

  get mapLayers(): L.Layer[] { return this.marker ? [this.marker] : []; }

  toggleCategory(cat: string, event: any) {
    if (event.target.checked) this.model.categories?.push(cat);
    else {
      const index = this.model.categories?.indexOf(cat);
      if (index !== undefined && index > -1) this.model.categories?.splice(index, 1);
    }
  }

  async onFileSelected(event: any) {
    const file = event.target.files[0];
    if (!file) return;

    this.uploadingImage = true;
    this.errorMessage = '';
    
    try {
      // Génération nom unique: timestamp_nom
      const fileName = Date.now() + '_' + file.name.replace(/[^a-zA-Z0-9.]/g, '_');
      const path = `places/${fileName}`;
      
      console.log('Début upload:', path);
      const url = await this.imageService.uploadImage(file, path);
      
      if (url) {
        this.model.images?.push(url);
      }
    } catch (err: any) {
      console.error('Upload failed', err);
      this.errorMessage = "Erreur Upload: " + (err.message || "Vérifiez votre config Supabase");
    } finally {
      this.uploadingImage = false;
    }
  }

  async onSubmit() {
    this.isSubmitting = true;
    this.errorMessage = '';

    try {
      const user = await firstValueFrom(this.auth.user$);
      if (!user) {
        this.errorMessage = "Vous devez être connecté.";
        this.isSubmitting = false;
        return;
      }

      const placeData: Place = {
        ...this.model as Place,
        createdBy: user.uid,
        createdAt: new Date(),
        status: 'approved' // Auto-approve pour simplifier le test
      };

      await this.placesService.addPlace(placeData);
      
      this.successMessage = "Lieu ajouté avec succès !";
      setTimeout(() => this.router.navigate(['/']), 1500);

    } catch (err) {
      console.error(err);
      this.errorMessage = "Erreur lors de l'enregistrement.";
    } finally {
      this.isSubmitting = false;
    }
  }
}
