import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './place-header.component.html'
})
export class PlaceHeaderComponent {
  @Input() place: Place | undefined;
  @Input() averageRating: number | null = null;
  @Input() commentsCount = 0;
  @Input() isLoggedIn = false;
  @Input() currentUserName = '';
}
