import { Component, EventEmitter, Input, Output, OnInit } from '@angular/core';
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
export class PlaceCommentsComponent implements OnInit {
  @Input() isLoggedIn = false;
  @Input() currentUserName: string | null = null;

  // pour satisfaire [comments]="comments" dans place-detail.component.html
  @Input() comments: PlaceComment[] = [];

  // pour satisfaire [isSubmitting]="isSubmittingComment" + logique dans le template
  @Input() isSubmitting = false;

  @Output() submitComment = new EventEmitter<{ rating: number; text: string }>();

  newRating = 5;
  newText = '';

  ngOnInit(): void {
    this.loadFromStorage();
  }

  private getStorageKey(): string {
    try {
      const path = window.location?.pathname ?? '';
      const match = path.match(/\/place\/([^/]+)/);
      const id = match ? match[1] : 'default';
      return `place-comments-${id}`;
    } catch {
      return 'place-comments-default';
    }
  }

  private loadFromStorage(): void {
    const key = this.getStorageKey();
    try {
      const raw = localStorage.getItem(key);
      if (!raw) {
        this.comments = [];
        return;
      }
      const parsed = JSON.parse(raw) as Array<{
        userName: string;
        rating: number;
        comment: string;
        createdAt: string;
      }>;
      this.comments = parsed.map((c) => ({
        userName: c.userName,
        rating: c.rating,
        comment: c.comment,
        createdAt: new Date(c.createdAt)
      }));
    } catch (e) {
      console.error('Erreur lors du chargement des commentaires', e);
      this.comments = [];
    }
  }

  private saveToStorage(): void {
    const key = this.getStorageKey();
    try {
      const payload = this.comments.map((c) => ({
        userName: c.userName,
        rating: c.rating,
        comment: c.comment,
        createdAt: c.createdAt.toISOString()
      }));
      localStorage.setItem(key, JSON.stringify(payload));
    } catch (e) {
      console.error('Erreur lors de la sauvegarde des commentaires', e);
    }
  }

  onSubmit(): void {
    const text = this.newText.trim();
    if (!this.isLoggedIn || !text) {
      return;
    }

    this.isSubmitting = true;

    const comment: PlaceComment = {
      userName: this.currentUserName || 'Utilisateur',
      rating: this.newRating,
      comment: text,
      createdAt: new Date()
    };

    // Ajout au tableau + persistance
    this.comments = [comment, ...this.comments];
    this.saveToStorage();

    // On notifie le parent (pour garder la compatibilité avec le handler existant)
    this.submitComment.emit({
      rating: this.newRating,
      text
    });

    this.newText = '';
    this.newRating = 5;
    this.isSubmitting = false;
  }

  toDate(value: any): any {
    if (!value) {
      return value;
    }
    const v: any = value as any;
    return v.toDate ? v.toDate() : v;
  }

}
