import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-media-gallery',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './place-media-gallery.component.html'
})
export class PlaceMediaGalleryComponent {
  @Input() place: Place | undefined;
  @Input() uploadingImages = false;
  @Input() uploadingVideos = false;
  @Input() uploadError: string | null = null;

  // Afficher les champs d'upload seulement en mode édition
  @Input() editMode = false;

  @Output() addImages = new EventEmitter<FileList>();
  @Output() addVideos = new EventEmitter<FileList>();

  // État pour la galerie plein écran
  isLightboxOpen = false;
  lightboxType: 'image' | 'video' | null = null;
  lightboxIndex = 0;

  get images(): string[] {
    return this.place?.images ?? [];
  }

  get videos(): string[] {
    // selon ton modèle, adapte le champ (videos, mediaVideos, etc.)
    // @ts-ignore
    return this.place?.videos ?? [];
  }

  onImagesSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length) {
      this.addImages.emit(input.files);
    }
  }

  onVideosSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length) {
      this.addVideos.emit(input.files);
    }
  }

  openImage(index: number) {
    if (this.images.length === 0) {
      return;
    }
    this.lightboxType = 'image';
    this.lightboxIndex = index;
    this.isLightboxOpen = true;
  }

  openVideo(index: number) {
    if (this.videos.length === 0) {
      return;
    }
    this.lightboxType = 'video';
    this.lightboxIndex = index;
    this.isLightboxOpen = true;
  }

  closeLightbox() {
    this.isLightboxOpen = false;
  }

  next() {
    if (!this.lightboxType) return;

    if (this.lightboxType === 'image' && this.images.length > 0) {
      this.lightboxIndex = (this.lightboxIndex + 1) % this.images.length;
    } else if (this.lightboxType === 'video' && this.videos.length > 0) {
      this.lightboxIndex = (this.lightboxIndex + 1) % this.videos.length;
    }
  }

  prev() {
    if (!this.lightboxType) return;

    if (this.lightboxType === 'image' && this.images.length > 0) {
      this.lightboxIndex =
        (this.lightboxIndex - 1 + this.images.length) % this.images.length;
    } else if (this.lightboxType === 'video' && this.videos.length > 0) {
      this.lightboxIndex =
        (this.lightboxIndex - 1 + this.videos.length) % this.videos.length;
    }
  }
}
