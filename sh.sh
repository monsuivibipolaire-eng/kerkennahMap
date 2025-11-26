#!/usr/bin/env bash
set -euo pipefail

# 1) Ne plus jamais afficher l'email comme nom
PD="src/app/features/map/pages/place-detail/place-detail.component.ts"

if [ -f "$PD" ]; then
  echo "➡️ Patch du nom utilisateur (suppression de l'email)..."
  sed -i.bak "s/user.fullName || user.name || user.email || 'Utilisateur'/user.fullName || user.name || 'Utilisateur'/g" "$PD" || true
else
  echo "⚠️ $PD introuvable, je passe cette étape."
fi

# 2) Réécriture complète du composant de commentaires
PC="src/app/features/map/components/place-comments.component.ts"

echo "➡️ Réécriture de $PC (avec @Input comments + isSubmitting et localStorage)..."
cat > "$PC" <<'TS'
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
}
TS

echo "✅ Terminé. Fichier sauvegardé : $PC"
echo "   Si besoin, tu peux restaurer l'ancienne version via git ou backup."
