import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

// Composants (Chemins basés sur l'architecture du script 02)
import { MapPageComponent } from './features/map/pages/map-page/map-page.component';
import { PlaceDetailComponent } from './features/map/pages/place-detail/place-detail.component';
import { AddPlaceComponent } from './features/admin/pages/add-place/add-place.component';
import { LoginComponent } from './features/auth/pages/login/login.component';
import { AdminListComponent } from './features/admin/pages/admin-list/admin-list.component';

// Guards
import { AuthGuard } from './core/guards/auth.guard';
import { AdminGuard } from './core/guards/admin.guard';

const routes: Routes = [
  // Route par défaut : Carte
  { path: '', component: MapPageComponent },

  // Détail d'un lieu
  { path: 'place/:id', component: PlaceDetailComponent },

  // Ajout d'un lieu (Protégé par AuthGuard)
  { path: 'add-place', component: AddPlaceComponent, canActivate: [AuthGuard] },

  // Login
  { path: 'login', component: LoginComponent },

  // Section Admin (Protégée par AdminGuard)
  { 
    path: 'admin',
    canActivate: [AdminGuard],
    children: [
        { path: 'places', component: AdminListComponent },
        // On pourrait ajouter une route pour les lieux 'pending' spécifiquement ici
        { path: 'places/pending', component: AdminListComponent }, 
        { path: '', redirectTo: 'places', pathMatch: 'full' }
    ]
  },

  // Redirection wildcard
  { path: '**', redirectTo: '' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
