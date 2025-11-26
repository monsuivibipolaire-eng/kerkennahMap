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

  @Output() addImages = new EventEmitter<FileList>();
  @Output() addVideos = new EventEmitter<FileList>();

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
}
