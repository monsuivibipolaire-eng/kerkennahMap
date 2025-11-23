import { Injectable, inject } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { Auth, authState, getIdTokenResult } from '@angular/fire/auth';
import { Observable } from 'rxjs';
import { map, take, switchMap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AdminGuard implements CanActivate {
  private auth = inject(Auth);
  private router = inject(Router);

  canActivate(): Observable<boolean | UrlTree> {
    // On écoute l'état d'authentification
    return authState(this.auth).pipe(
      take(1), // On prend juste la valeur actuelle
      switchMap(async (user) => {
        if (!user) {
          console.warn('AdminGuard: Pas d\'utilisateur connecté.');
          return false;
        }

        // On force le rafraîchissement du token pour avoir les derniers claims
        // (Important si on vient de lancer le script setAdmin.js)
        const tokenResult = await getIdTokenResult(user, true);
        
        // On vérifie si le claim 'admin' est présent et vrai
        const isAdmin = !!tokenResult.claims['admin'];

        if (isAdmin) {
          console.log('✅ AdminGuard: Accès autorisé.');
          return true;
        } else {
          console.error('⛔ AdminGuard: Accès refusé. Claims:', tokenResult.claims);
          return false;
        }
      }),
      map(isAuthorized => {
        if (isAuthorized) return true;
        
        // Si refusé, redirection vers l'accueil avec un paramètre d'erreur
        // return this.router.createUrlTree(['/'], { queryParams: { error: 'admin_required' } });
        
        // Ou simplement false (la page ne chargera pas)
        alert('Accès refusé : droits administrateur requis');
        return this.router.createUrlTree(['/']); 
      })
    );
  }
}
