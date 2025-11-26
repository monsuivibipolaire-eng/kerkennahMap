import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LeafletModule } from '@bluehalo/ngx-leaflet';
import * as L from 'leaflet';

@Component({
  selector: 'app-place-map-card',
  standalone: true,
  imports: [CommonModule, LeafletModule],
  templateUrl: './place-map-card.component.html'
})
export class PlaceMapCardComponent {
  @Input() mapOptions!: L.MapOptions;
  @Input() mapLayers: L.Layer[] = [];
}
