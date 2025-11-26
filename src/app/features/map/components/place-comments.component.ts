import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

export interface PlaceComment {
  userName: string;
  rating: number;
  comment: string;
  createdAt: Date;
}

@Component({
  selector: 'app-place-comments',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './place-comments.component.html'
})
export class PlaceCommentsComponent {
  @Input() comments: PlaceComment[] = [];
  @Input() isLoggedIn = false;
  @Input() currentUserName: string | null = null;
  @Input() isSubmitting = false;

  @Output() submitComment = new EventEmitter<{ rating: number; text: string }>();

  newRating = 5;
  newText = '';

  onSubmit() {
    const text = this.newText.trim();
    if (!text || !this.isLoggedIn) return;

    this.submitComment.emit({
      rating: this.newRating,
      text
    });

    this.newText = '';
    this.newRating = 5;
  }
}
