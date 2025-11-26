import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './place-header.component.html'
})
export class PlaceHeaderComponent {
  @Input() place: Place | undefined;
  @Input() averageRating: number | null = null;
  @Input() commentsCount = 0;
}
