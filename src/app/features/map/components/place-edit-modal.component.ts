import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Place } from '../../../core/models/place.model';

@Component({
  selector: 'app-place-edit-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './place-edit-modal.component.html'
})
export class PlaceEditModalComponent {
  @Input() place: Place | null = null;
  @Input() categories: string[] = [];
  @Input() isSaving = false;
  @Input() uploadError: string | null = null;

  @Output() cancel = new EventEmitter<void>();
  @Output() save = new EventEmitter<Place>();

  onCancel() {
    this.cancel.emit();
  }

  onSubmit() {
    if (!this.place) return;
    this.save.emit(this.place);
  }
}
