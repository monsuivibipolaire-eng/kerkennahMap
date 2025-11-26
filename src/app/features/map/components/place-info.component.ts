import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-info',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './place-info.component.html'
})
export class PlaceInfoComponent {
  @Input() place: Place | undefined;
}
