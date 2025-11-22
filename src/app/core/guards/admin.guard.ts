import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { map, take, tap } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root'
})
export class AdminGuard implements CanActivate {
  constructor(private auth: AuthService, private router: Router) {}

  canActivate(): Observable<boolean> {
    return this.auth.user$.pipe(
      take(1),
      map(user => {
        // Vérifie si l'utilisateur existe et a le rôle 'admin'
        return !!(user && user.roles.includes('admin'));
      }),
      tap(isAdmin => {
        if (!isAdmin) {
          console.log('Accès refusé : droits administrateur requis');
          this.router.navigate(['/']);
        }
      })
    );
  }
}
