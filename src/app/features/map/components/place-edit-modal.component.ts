import { Component, EventEmitter, Input, Output, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import * as L from 'leaflet';
import { Place } from '../../../core/models/place.model';
import { SupabaseImageService } from '../../../core/services/supabase-image.service';
import { PlaceMapCardComponent } from './place-map-card.component';

@Component({
  selector: 'app-place-edit-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, LeafletModule, PlaceMapCardComponent],
  templateUrl: './place-edit-modal.component.html'
})
export class PlaceEditModalComponent implements OnChanges {
  @Input() place: Place | null = null;
  @Input() categories: string[] = [];
  @Input() isSaving = false;
  @Input() uploadError: string | null = null;

  @Output() cancel = new EventEmitter<void>();
  @Output() save = new EventEmitter<Place>();

  // États d'upload
  uploadingImages = false;
  uploadingVideos = false;

  // Carte
  mapOptions: L.MapOptions = {
    layers: [
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '© OpenStreetMap'
      })
    ],
    zoom: 14,
    center: L.latLng(34.71, 11.15)
  };

  mapLayers: L.Layer[] = [];

  constructor(private imageService: SupabaseImageService) {
    // Patch des icônes Leaflet (comme dans AddPlaceComponent)
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
      this.updateMap(this.place.latitude, this.place.longitude);

      if (!this.place.images) {
        this.place.images = [];
      }
      if (!this.place.videos) {
        this.place.videos = [];
      }
    }
  }

  private updateMap(lat: number, lng: number): void {
    this.mapOptions = {
      ...this.mapOptions,
      center: L.latLng(lat, lng)
    };

    this.mapLayers = [
      L.marker([lat, lng])
    ];
  }

  onCancel(): void {
    this.cancel.emit();
  }

  onSubmit(): void {
    if (!this.place || this.isSaving) return;
    this.save.emit(this.place);
  }

  // Upload d'IMAGES
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

  // Upload de VIDEOS
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
