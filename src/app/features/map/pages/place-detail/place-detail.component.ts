import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

import { PlaceAdminActionsComponent } from '../../components/place-admin-actions.component';
import { PlaceHeaderComponent } from '../../components/place-header.component';
import { PlaceMediaGalleryComponent } from '../../components/place-media-gallery.component';
import { PlaceInfoComponent } from '../../components/place-info.component';
import { PlaceCommentsComponent } from '../../components/place-comments.component';
import { PlaceMapCardComponent } from '../../components/place-map-card.component';
import { PlaceEditModalComponent } from '../../components/place-edit-modal.component';

import { PlacesService } from '../../../../core/services/places.service';
import { AuthService } from '../../../../core/services/auth.service';
import { Place } from '../../../../core/models/place.model';
import { firstValueFrom } from 'rxjs';

interface PlaceComment {
  userName: string;
  rating: number;
  comment: string;
  createdAt: Date;
}

@Component({
  selector: 'app-place-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    PlaceAdminActionsComponent,
    PlaceHeaderComponent,
    PlaceMediaGalleryComponent,
    PlaceInfoComponent,
    PlaceCommentsComponent,
    PlaceMapCardComponent,
    PlaceEditModalComponent
  ],
  templateUrl: './place-detail.component.html',
  styleUrls: ['./place-detail.component.scss']
})
export class PlaceDetailComponent implements OnInit {
  // Peut être null ou undefined selon le service
  place: Place | null | undefined = null;

  comments: PlaceComment[] = [];

  isAdmin = false;
  isLoggedIn = false;
  currentUserName = '';
  isSubmittingComment = false;

  uploadingImages = false;
  uploadingVideos = false;
  uploadError: string | null = null;

  showEditModal = false;
  editingPlace: Place | null = null;
  availableCategories: string[] = [
    'Hébergement',
    'Restaurant',
    'Site à visiter',
    'Transport'
  ];
  isSavingPlace = false;

  mapOptions: any = {
    center: [34.71, 11.15],
    zoom: 13
  };
  mapLayers: any[] = [];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private placesService: PlacesService,
    private authService: AuthService
  ) {}

  async ngOnInit(): Promise<void> {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      return;
    }

    this.place = await firstValueFrom(this.placesService.getPlaceById(id));

    const user = await firstValueFrom(this.authService.user$);

    this.isLoggedIn = !!user;
    this.isAdmin =
      !!user &&
      Array.isArray((user as any).roles) &&
      (user as any).roles.includes('admin');

    this.currentUserName =
      (user as any)?.displayName ||
      (user as any)?.email ||
      'Utilisateur';

    if (
      this.place &&
      typeof this.place.latitude === 'number' &&
      typeof this.place.longitude === 'number'
    ) {
      this.mapOptions = {
        ...this.mapOptions,
        center: [this.place.latitude, this.place.longitude]
      };
      this.mapLayers = [
        {
          lat: this.place.latitude,
          lng: this.place.longitude
        }
      ];
    }

    if (id) {
      this.loadCommentsFromStorage(id);
    }
  }

  get hasPlace(): boolean {
    return !!this.place;
  }

  get averageRating(): number {
    if (!this.comments.length) {
      return 0;
    }
    const sum = this.comments.reduce((acc, c) => acc + c.rating, 0);
    return sum / this.comments.length;
  }

  private loadCommentsFromStorage(placeId: string): void {
    try {
      const key = `place-comments-${placeId}`;
      const raw = localStorage.getItem(key);
      if (!raw) {
        this.comments = [];
        return;
      }
      const parsed = JSON.parse(raw) as any[];
      this.comments = parsed.map((c) => ({
        userName: c.userName || 'Utilisateur',
        rating: c.rating,
        comment: c.comment,
        createdAt: new Date(c.createdAt)
      }));
    } catch (e) {
      console.error('Erreur lors du chargement des commentaires', e);
      this.comments = [];
    }
  }

  private saveCommentsToStorage(): void {
    if (!this.place || !this.place.id) {
      return;
    }
    try {
      const key = `place-comments-${this.place.id}`;
      const payload = this.comments.map((c) => ({
        ...c,
        createdAt: c.createdAt.toISOString()
      }));
      localStorage.setItem(key, JSON.stringify(payload));
    } catch (e) {
      console.error('Erreur lors de la sauvegarde des commentaires', e);
    }
  }

  // === Actions administrateur ===

  openEditModal(): void {
    if (!this.place) {
      return;
    }
    this.editingPlace = JSON.parse(JSON.stringify(this.place));
    this.showEditModal = true;
  }

  closeEditModal(): void {
    this.showEditModal = false;
  }

  onDeletePlace(): void {
    if (!this.place || !this.place.id) {
      return;
    }
    if (!confirm('Supprimer ce lieu ?')) {
      return;
    }
    this.placesService.deletePlace(this.place.id).then(() => {
      this.router.navigate(['/']);
    });
  }

  // === Upload média depuis app-place-media-gallery ===
  // Ici on accepte n'importe quel type (FileList, string[], ...)

  onUploadImages(event: any): void {
    console.log('onUploadImages event', event);
    // La logique d’upload réelle est probablement dans le composant enfant.
    // Ici on pourrait plus tard mettre à jour this.place / this.editingPlace si besoin.
  }

  onUploadVideos(event: any): void {
    console.log('onUploadVideos event', event);
  }

  // === Commentaires (app-place-comments) ===

  onSubmitComment(event: any): void {
    if (!this.place || !this.place.id) {
      return;
    }

    this.isSubmittingComment = true;

    const newComment: PlaceComment = {
      userName: event.userName || this.currentUserName || 'Utilisateur',
      rating: event.rating,
      comment: event.comment ?? event.text ?? '',
      createdAt: new Date()
    };

    this.comments = [newComment, ...this.comments];
    this.saveCommentsToStorage();

    this.isSubmittingComment = false;
  }

  // === Sauvegarde depuis la modale d’édition ===

  onSaveEditedPlace(event: any): void {
    if (event) {
      this.editingPlace = event as Place;
    }
    this.savePlace();
  }

  private async savePlace(): Promise<void> {
    if (!this.editingPlace || !this.editingPlace.id) {
      return;
    }

    try {
      this.isSavingPlace = true;
      await this.placesService.updatePlace(
        this.editingPlace.id,
        this.editingPlace
      );
      this.place = this.editingPlace;
      this.showEditModal = false;
    } catch (e) {
      console.error('Erreur lors de la sauvegarde du lieu', e);
    } finally {
      this.isSavingPlace = false;
    }
  }
}
