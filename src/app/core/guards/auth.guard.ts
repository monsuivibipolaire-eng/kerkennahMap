import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { map, take, tap } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  constructor(private auth: AuthService, private router: Router) {}

  canActivate(): Observable<boolean> {
    return this.auth.user$.pipe(
      take(1),
      map(user => !!user), // Transforme l'objet user en booléen
      tap(loggedIn => {
        if (!loggedIn) {
          console.log('Accès refusé : connexion requise');
          this.router.navigate(['/login']);
        }
      })
    );
  }
}
