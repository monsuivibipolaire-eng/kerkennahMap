#!/usr/bin/env bash
set -euo pipefail

# Script : adapter la page "admin" pour :
# - SI ADMIN  -> voir les lieux en attente de validation (comme avant)
# - SI NON ADMIN -> voir SES lieux créés (createdBy == user) et,
#                  s'il n'en a aucun, afficher un bouton "Ajouter un lieu"
#
# À lancer depuis la racine du projet (là où il y a le dossier src/)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    cp "$f" "$f.bak.$(date +%Y%m%d_%H%M%S)"
  fi
}

echo "📦 Backup des fichiers..."
backup "src/app/core/services/places.service.ts"
backup "src/app/features/admin/pages/admin-list/admin-list.component.ts"
backup "src/app/features/admin/pages/admin-list/admin-list.component.html"

############################################
# 1) Service PlacesService : + getPlacesByUser
############################################
cat > src/app/core/services/places.service.ts <<'EOF'
import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  collection,
  collectionData,
  doc,
  docData,
  addDoc,
  query,
  where,
  updateDoc,
  deleteDoc
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Place } from '../models/place.model';

@Injectable({
  providedIn: 'root'
})
export class PlacesService {
  private firestore: Firestore = inject(Firestore);

  constructor() {}

  // Lieux approuvés (affichés sur la carte)
  getApprovedPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'approved'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // Lieu par ID
  getPlaceById(id: string): Observable<Place | undefined> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return docData(placeDocRef, { idField: 'id' }) as Observable<Place>;
  }

  // ➕ Ajouter un lieu
  addPlace(place: Place): Promise<any> {
    const placesRef = collection(this.firestore, 'places');
    return addDoc(placesRef, place);
  }

  // ✏️ Mise à jour générique
  updatePlace(id: string, data: Partial<Place>): Promise<void> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return updateDoc(placeDocRef, data as any);
  }

  // 🗑 Supprimer un lieu
  deletePlace(id: string): Promise<void> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return deleteDoc(placeDocRef);
  }

  // 🕒 Lieux en attente (pour admin)
  getPendingPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'pending'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // 👤 Lieux créés par un utilisateur donné (pour non-admin)
  getPlacesByUser(userId: string): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('createdBy', '==', userId));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // ✅ Approuver un lieu (admin)
  approvePlace(id: string, adminId: string): Promise<void> {
    return this.updatePlace(id, {
      status: 'approved',
      validatedBy: adminId,
      validatedAt: new Date(),
      updatedAt: new Date()
    });
  }

  // ❌ Rejeter un lieu (admin)
  rejectPlace(id: string): Promise<void> {
    return this.updatePlace(id, {
      status: 'rejected',
      updatedAt: new Date()
    });
  }
}
EOF

############################################
# 2) AdminListComponent TS : vue admin vs vue utilisateur
############################################
cat > src/app/features/admin/pages/admin-list/admin-list.component.ts <<'EOF'
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Observable, of, firstValueFrom } from 'rxjs';

import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-admin-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './admin-list.component.html',
  styles: [`
    .card { @apply bg-white rounded-lg shadow p-6 mb-4; }
    .btn { @apply px-3 py-2 rounded text-sm font-semibold transition; }
    .btn-approve { @apply bg-green-600 text-white hover:bg-green-700; }
    .btn-reject { @apply bg-red-600 text-white hover:bg-red-700; }
    .badge { @apply inline-block text-xs px-2 py-1 rounded-full; }
  `]
})
export class AdminListComponent implements OnInit {
  private placesService = inject(PlacesService);
  private authService = inject(AuthService);

  // Pour admins : lieux en attente
  pendingPlaces$: Observable<Place[]> = of([]);

  // Pour non-admins : leurs propres lieux
  userPlaces$: Observable<Place[]> = of([]);

  isAdmin = false;
  currentUserId: string | null = null;

  isProcessingId: string | null = null;
  message = '';

  ngOnInit(): void {
    this.authService.user$.subscribe(user => {
      if (!user) {
        this.isAdmin = false;
        this.currentUserId = null;
        this.pendingPlaces$ = of([]);
        this.userPlaces$ = of([]);
        return;
      }

      const roles = (user as any)?.roles;
      const uid = (user as any)?.uid || (user as any)?.id || null;

      this.currentUserId = uid;
      this.isAdmin = Array.isArray(roles) && roles.includes('admin');

      if (this.isAdmin) {
        // 🛡 Admin : voit les lieux en attente
        this.pendingPlaces$ = this.placesService.getPendingPlaces();
        this.userPlaces$ = of([]);
      } else if (uid) {
        // 👤 Utilisateur normal : voit SES lieux ajoutés
        this.userPlaces$ = this.placesService.getPlacesByUser(uid);
        this.pendingPlaces$ = of([]);
      }
    });
  }

  // ✅ Valider un lieu (admin uniquement)
  async approve(place: Place) {
    if (!place.id) return;

    this.isProcessingId = place.id;
    this.message = '';

    try {
      const admin = await firstValueFrom(this.authService.user$);
      const adminId =
        (admin as any)?.uid ||
        (admin as any)?.id ||
        null;

      if (!this.isAdmin || !adminId) {
        this.message = '❌ Action réservée aux administrateurs.';
        this.isProcessingId = null;
        return;
      }

      await this.placesService.approvePlace(place.id, adminId);
      this.message = `✅ Lieu "${place.name}" approuvé.`;
    } catch (err) {
      console.error(err);
      this.message = `❌ Erreur lors de la validation de "${place.name}".`;
    } finally {
      this.isProcessingId = null;
    }
  }

  // ❌ Rejeter un lieu (admin uniquement)
  async reject(place: Place) {
    if (!place.id) return;

    const confirmReject = window.confirm(
      `Êtes-vous sûr de vouloir rejeter le lieu "${place.name}" ?`
    );
    if (!confirmReject) return;

    this.isProcessingId = place.id;
    this.message = '';

    try {
      if (!this.isAdmin) {
        this.message = '❌ Action réservée aux administrateurs.';
        this.isProcessingId = null;
        return;
      }

      await this.placesService.rejectPlace(place.id);
      this.message = `✅ Lieu "${place.name}" rejeté.`;
    } catch (err) {
      console.error(err);
      this.message = `❌ Erreur lors du rejet de "${place.name}".`;
    } finally {
      this.isProcessingId = null;
    }
  }
}
EOF

############################################
# 3) AdminListComponent HTML : vue admin + vue utilisateur
############################################
cat > src/app/features/admin/pages/admin-list/admin-list.component.html <<'EOF'
<div class="container mx-auto p-6">
  <!-- Titre différent selon rôle -->
  <h1 class="text-3xl font-bold text-blue-900 mb-6">
    <ng-container *ngIf="isAdmin; else userTitle">
      Administration – Modération des lieux
    </ng-container>
    <ng-template #userTitle>
      Mes lieux
    </ng-template>
  </h1>

  <!-- Message global -->
  <div
    *ngIf="message"
    class="mb-4 p-3 rounded border text-sm"
    [ngClass]="{
      'bg-green-50 text-green-700 border-green-200': message.startsWith('✅'),
      'bg-red-50 text-red-700 border-red-200': message.startsWith('❌')
    }"
  >
    {{ message }}
  </div>

  <!-- VUE ADMIN : lieux en attente -->
  <ng-container *ngIf="isAdmin; else userView">
    <ng-container *ngIf="pendingPlaces$ | async as pending; else loadingAdmin">
      <div *ngIf="pending.length === 0" class="text-gray-500 italic">
        Aucun lieu en attente de validation pour le moment.
      </div>

      <div *ngFor="let place of pending" class="card">
        <div class="flex flex-col md:flex-row md:items-start gap-4">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-1">
              <h2 class="text-lg font-semibold text-gray-900">
                {{ place.name }}
              </h2>
              <span class="badge bg-yellow-100 text-yellow-800 border border-yellow-200">
                En attente
              </span>
            </div>

            <p class="text-sm text-gray-600 mb-2">
              {{ place.description || 'Aucune description.' }}
            </p>

            <div class="flex flex-wrap gap-2 mb-2">
              <span
                *ngFor="let cat of place.categories"
                class="badge bg-blue-50 text-blue-700 border border-blue-100"
              >
                {{ cat }}
              </span>
            </div>

            <p class="text-xs text-gray-500">
              <span class="font-semibold">Position :</span>
              {{ place.latitude | number : '1.4-4' }},
              {{ place.longitude | number : '1.4-4' }}
            </p>

            <p class="text-xs text-gray-400 mt-1">
              Proposé par :
              <span class="font-mono">
                {{ place.createdBy || 'inconnu' }}
              </span>
            </p>
          </div>

          <div class="flex flex-col items-stretch gap-2 md:w-48">
            <a
              [routerLink]="['/place', place.id]"
              class="btn bg-blue-50 text-blue-700 border border-blue-200 hover:bg-blue-100 text-center"
            >
              👁 Voir la fiche
            </a>

            <button
              type="button"
              (click)="approve(place)"
              [disabled]="isProcessingId === place.id"
              class="btn btn-approve disabled:opacity-50 disabled:cursor-not-allowed"
            >
              ✅ Valider
            </button>

            <button
              type="button"
              (click)="reject(place)"
              [disabled]="isProcessingId === place.id"
              class="btn btn-reject disabled:opacity-50 disabled:cursor-not-allowed"
            >
              ❌ Rejeter
            </button>
          </div>
        </div>
      </div>
    </ng-container>

    <ng-template #loadingAdmin>
      <div class="text-gray-500 italic">Chargement des lieux en attente...</div>
    </ng-template>
  </ng-container>

  <!-- VUE UTILISATEUR (non admin) : ses lieux -->
  <ng-template #userView>
    <ng-container *ngIf="userPlaces$ | async as myPlaces; else loadingUser">
      <!-- Aucun lieu : bouton Ajouter -->
      <div *ngIf="myPlaces.length === 0" class="bg-white rounded-lg border border-dashed border-gray-300 p-6 text-center">
        <p class="text-gray-600 mb-3">
          Vous n'avez encore ajouté aucun lieu.
        </p>
        <a
          routerLink="/add-place"
          class="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-600 text-white text-sm font-semibold shadow hover:bg-blue-700 transition"
        >
          ➕ Ajouter un lieu
        </a>
      </div>

      <!-- Liste des lieux ajoutés par l'utilisateur -->
      <div *ngFor="let place of myPlaces" class="card">
        <div class="flex flex-col md:flex-row md:items-start gap-4">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-1">
              <h2 class="text-lg font-semibold text-gray-900">
                {{ place.name }}
              </h2>
              <span
                class="badge border"
                [ngClass]="{
                  'bg-yellow-50 text-yellow-700 border-yellow-200': place.status === 'pending',
                  'bg-green-50 text-green-700 border-green-200': place.status === 'approved',
                  'bg-red-50 text-red-700 border-red-200': place.status === 'rejected'
                }"
              >
                <ng-container [ngSwitch]="place.status">
                  <span *ngSwitchCase="'pending'">En attente</span>
                  <span *ngSwitchCase="'approved'">Publié</span>
                  <span *ngSwitchCase="'rejected'">Rejeté</span>
                  <span *ngSwitchDefault>{{ place.status }}</span>
                </ng-container>
              </span>
            </div>

            <p class="text-sm text-gray-600 mb-2">
              {{ place.description || 'Aucune description.' }}
            </p>

            <div class="flex flex-wrap gap-2 mb-2">
              <span
                *ngFor="let cat of place.categories"
                class="badge bg-blue-50 text-blue-700 border border-blue-100"
              >
                {{ cat }}
              </span>
            </div>

            <p class="text-xs text-gray-500">
              <span class="font-semibold">Position :</span>
              {{ place.latitude | number : '1.4-4' }},
              {{ place.longitude | number : '1.4-4' }}
            </p>
          </div>

          <div class="flex flex-col items-stretch gap-2 md:w-48">
            <a
              [routerLink]="['/place', place.id]"
              class="btn bg-blue-50 text-blue-700 border border-blue-200 hover:bg-blue-100 text-center"
            >
              👁 Voir la fiche
            </a>
          </div>
        </div>
      </div>
    </ng-container>

    <ng-template #loadingUser>
      <div class="text-gray-500 italic">Chargement de vos lieux...</div>
    </ng-template>
  </ng-template>
</div>
EOF

echo "✅ Patch terminé :"
echo "  - Si ADMIN : /admin affiche les lieux en attente (modération)."
echo "  - Si NON ADMIN : /admin affiche les lieux ajoutés par l'utilisateur,"
echo "    et si aucun, un bouton 'Ajouter un lieu' est affiché."
