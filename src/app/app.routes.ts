import { Routes } from '@angular/router';
import { MapPageComponent } from './features/map/pages/map-page/map-page.component';
import { PlaceDetailComponent } from './features/map/pages/place-detail/place-detail.component';
import { AddPlaceComponent } from './features/admin/pages/add-place/add-place.component';
import { LoginComponent } from './features/auth/pages/login/login.component';
import { AdminListComponent } from './features/admin/pages/admin-list/admin-list.component';
import { AuthGuard } from './core/guards/auth.guard';
import { AdminGuard } from './core/guards/admin.guard';

export const routes: Routes = [
  { path: '', component: MapPageComponent },
  { path: 'place/:id', component: PlaceDetailComponent },
  { path: 'add-place', component: AddPlaceComponent, canActivate: [AuthGuard] },
  { path: 'login', component: LoginComponent },
  { 
    path: 'admin',
    canActivate: [AdminGuard],
    children: [
        { path: 'places', component: AdminListComponent },
        { path: '', redirectTo: 'places', pathMatch: 'full' }
    ]
  },
  { path: '**', redirectTo: '' }
];
