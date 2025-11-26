import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-admin-actions',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './place-admin-actions.component.html'
})
export class PlaceAdminActionsComponent {
  @Input() place: Place | undefined;
  @Input() isAdmin = false;

  @Output() edit = new EventEmitter<Place>();
  @Output() delete = new EventEmitter<Place>();

  onEdit() {
    if (this.place) this.edit.emit(this.place);
  }

  onDelete() {
    if (this.place) this.delete.emit(this.place);
  }
}
