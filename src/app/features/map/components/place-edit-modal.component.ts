import { Component, EventEmitter, Input, Output, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import * as L from 'leaflet';
import { Place } from '../../../core/models/place.model';
import { SupabaseImageService } from '../../../core/services/supabase-image.service';

@Component({
  selector: 'app-place-edit-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, LeafletModule],
  templateUrl: './place-edit-modal.component.html'
})
export class PlaceEditModalComponent implements OnChanges {
  @Input() place: Place | null = null;
  @Input() categories: string[] = [];
  @Input() isSaving = false;
  @Input() uploadError: string | null = null;

  @Output() cancel = new EventEmitter<void>();
  @Output() save = new EventEmitter<Place>();

  uploadingImages = false;
  uploadingVideos = false;
  saveSuccess = false;

  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 18,
        attribution: '© OpenStreetMap'
      })
    ],
    zoom: 13,
    center: L.latLng(34.71, 11.15)
  };

  marker: L.Marker | null = null;

  constructor(private imageService: SupabaseImageService) {
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

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['place'] && this.place) {
      if (!this.place.images) this.place.images = [];
      if (!this.place.videos) this.place.videos = [];

      if (typeof this.place.latitude === 'number' && typeof this.place.longitude === 'number') {
        this.mapOptions = {
          ...this.mapOptions,
          center: L.latLng(this.place.latitude, this.place.longitude)
        };
        this.updateMarker(this.place.latitude, this.place.longitude);
      }

      // Quand on ouvre la modale, on réinitialise le message de succès
      this.saveSuccess = false;
    }
  }

  onMapReady(map: L.Map): void {
    // Clic sur la carte -> déplace le marqueur et met à jour les coords
    map.on('click', (e: L.LeafletMouseEvent) => {
      if (!this.place) return;
      this.place.latitude = e.latlng.lat;
      this.place.longitude = e.latlng.lng;
      this.updateMarker(e.latlng.lat, e.latlng.lng);
    });

    if (this.place && typeof this.place.latitude === 'number' && typeof this.place.longitude === 'number') {
      this.updateMarker(this.place.latitude, this.place.longitude);
      map.setView([this.place.latitude, this.place.longitude], this.mapOptions.zoom || 13);
    }
  }

  private updateMarker(lat: number, lng: number): void {
    if (this.marker) {
      this.marker.setLatLng([lat, lng]);
    } else {
      this.marker = L.marker([lat, lng]);
    }
  }

  get mapLayers(): L.Layer[] {
    return this.marker ? [this.marker] : [];
  }

  onCancel(): void {
    this.saveSuccess = false;
    this.cancel.emit();
  }

  onSubmit(): void {
    if (!this.place || this.isSaving) return;
    this.save.emit(this.place);
    // On cache le formulaire et on affiche un message de succès
    this.saveSuccess = true;
  }

  async onImagesSelected(event: Event): Promise<void> {
    if (!this.place) return;

    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const files = Array.from(input.files);
    this.uploadingImages = true;
    this.uploadError = null;

    try {
      if (!this.place.images) this.place.images = [];

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `images/${fileName}`;
        const url = await this.imageService.uploadImage(file, path);
        if (url) this.place.images.push(url);
      }

      input.value = '';
    } catch (err: any) {
      console.error('Upload images failed', err);
      this.uploadError =
        "Erreur lors de l'upload des images : " +
        (err?.message || 'Vérifiez votre configuration Supabase');
    } finally {
      this.uploadingImages = false;
    }
  }

  async onVideosSelected(event: Event): Promise<void> {
    if (!this.place) return;

    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const files = Array.from(input.files);
    this.uploadingVideos = true;
    this.uploadError = null;

    try {
      if (!this.place.videos) this.place.videos = [];

      for (const file of files) {
        const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, '_');
        const fileName = `${Date.now()}_${safeName}`;
        const path = `videos/${fileName}`;
        const url = await this.imageService.uploadImage(file, path);
        if (url) this.place.videos.push(url);
      }

      input.value = '';
    } catch (err: any) {
      console.error('Upload videos failed', err);
      this.uploadError =
        "Erreur lors de l'upload des vidéos : " +
        (err?.message || 'Vérifiez votre configuration Supabase');
    } finally {
      this.uploadingVideos = false;
    }
  }

  removeImage(url: string): void {
    if (!this.place || !this.place.images) return;
    this.place.images = this.place.images.filter(i => i !== url);
  }

  removeVideo(url: string): void {
    if (!this.place || !this.place.videos) return;
    this.place.videos = this.place.videos.filter(v => v !== url);
  }
}
