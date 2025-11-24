#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    cp "$f" "$f.bak.$(date +%Y%m%d_%H%M%S)"
  fi
}

echo "📦 Backup des fichiers header..."
backup "src/app/core/components/header/header.component.ts"
backup "src/app/core/components/header/header.component.html"

############################################
# 1) header.component.ts : expose user$ + menu mobile
############################################
cat > src/app/core/components/header/header.component.ts <<'EOF'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { Observable } from 'rxjs';

import { AuthService } from '../../services/auth.service';
import { User } from '../../models/user.model';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css']
})
export class HeaderComponent {
  user$: Observable<User | null | undefined>;
  isMobileMenuOpen = false;

  constructor(private auth: AuthService, private router: Router) {
    this.user$ = this.auth.user$;
  }

  toggleMobileMenu() {
    this.isMobileMenuOpen = !this.isMobileMenuOpen;
  }

  async logout() {
    await this.auth.signOut();
    this.router.navigate(['/login']);
    this.isMobileMenuOpen = false;
  }
}
EOF

############################################
# 2) header.component.html : bouton Admin seulement pour les admins
############################################
cat > src/app/core/components/header/header.component.html <<'EOF'
<header class="bg-blue-900 text-white shadow-md sticky top-0 z-50">
  <div class="container mx-auto px-4 py-3">
    <div class="flex justify-between items-center">
      
      <!-- Logo -->
      <a
        routerLink="/"
        class="flex items-center gap-2 text-xl font-bold tracking-wider hover:text-blue-200 transition"
      >
        <span class="text-2xl">🏝️</span>
        <span class="hidden sm:inline">Kerkennah Map</span>
      </a>

      <!-- Navigation Desktop -->
      <nav class="hidden md:flex items-center space-x-6">
        <a
          routerLink="/"
          routerLinkActive="text-yellow-400"
          class="hover:text-blue-200 font-medium transition"
        >
          Carte
        </a>

        <!-- Liens visibles seulement quand connecté -->
        <ng-container *ngIf="user$ | async as user">
          <a
            routerLink="/add-place"
            routerLinkActive="text-yellow-400"
            class="hover:text-blue-200 transition"
          >
            Ajouter un lieu
          </a>

          <!-- 🔐 Bouton Admin visible uniquement si l'utilisateur est admin -->
          <a
            *ngIf="user.roles?.includes('admin')"
            routerLink="/admin"
            routerLinkActive="text-yellow-400"
            class="hover:text-blue-200 transition"
          >
            Admin
          </a>
        </ng-container>
      </nav>

      <!-- Zone Utilisateur Desktop -->
      <div class="hidden md:flex items-center gap-4">
        <ng-container *ngIf="user$ | async as user; else loginBtn">
          <div class="text-right">
            <p class="text-xs text-blue-300">Connecté en tant que</p>
            <p class="text-sm font-semibold">{{ user.email }}</p>
          </div>
          <button
            (click)="logout()"
            class="bg-red-500/80 hover:bg-red-500 text-white text-sm px-3 py-2 rounded-full font-semibold shadow-sm transition"
          >
            Déconnexion
          </button>
        </ng-container>

        <ng-template #loginBtn>
          <a
            routerLink="/login"
            class="bg-yellow-400 text-blue-900 px-4 py-2 rounded-full font-semibold shadow-sm hover:bg-yellow-300 transition text-sm"
          >
            Connexion
          </a>
        </ng-template>
      </div>

      <!-- Bouton Menu Mobile -->
      <button
        class="md:hidden flex items-center justify-center w-10 h-10 rounded-full bg-blue-800 hover:bg-blue-700 transition"
        (click)="toggleMobileMenu()"
        type="button"
        aria-label="Menu"
      >
        <svg
          *ngIf="!isMobileMenuOpen"
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M4 6h16M4 12h16M4 18h16" />
        </svg>
        <svg
          *ngIf="isMobileMenuOpen"
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <!-- Menu Mobile -->
    <div
      class="md:hidden mt-3 rounded-lg bg-blue-800/80 backdrop-blur border border-blue-700"
      *ngIf="isMobileMenuOpen"
    >
      <ng-container *ngIf="user$ | async as user; else mobileLogin">
        <nav class="flex flex-col gap-2 px-4 py-3">
          <a
            routerLink="/"
            (click)="isMobileMenuOpen=false"
            routerLinkActive="text-yellow-400"
            class="py-1 border-b border-blue-700/60 hover:text-yellow-300 transition"
          >
            Carte
          </a>

          <a
            routerLink="/add-place"
            (click)="isMobileMenuOpen=false"
            routerLinkActive="text-yellow-400"
            class="py-1 border-b border-blue-700/60 hover:text-yellow-300 transition"
          >
            Ajouter un lieu
          </a>

          <!-- 🔐 Bouton Admin sur mobile seulement si admin -->
          <a
            *ngIf="user.roles?.includes('admin')"
            routerLink="/admin"
            (click)="isMobileMenuOpen=false"
            routerLinkActive="text-yellow-400"
            class="py-1 border-b border-blue-700/60 hover:text-yellow-300 transition"
          >
            Admin
          </a>

          <div class="pt-2">
            <p class="text-xs text-blue-300 mb-1">Connecté en tant que</p>
            <p class="text-sm text-white mb-3 font-medium">
              {{ user.email }}
            </p>
            <button
              (click)="logout()"
              class="w-full text-center py-2 rounded-full bg-red-500/80 hover:bg-red-500 transition font-bold text-sm"
            >
              Déconnexion
            </button>
          </div>
        </nav>
      </ng-container>

      <ng-template #mobileLogin>
        <div class="px-4 py-3">
          <a
            routerLink="/login"
            (click)="isMobileMenuOpen=false"
            class="block w-full bg-yellow-400 text-blue-900 py-2 rounded-full font-bold text-center shadow-sm hover:bg-yellow-300 transition text-sm"
          >
            Connexion
          </a>
        </div>
      </ng-template>
    </div>
  </div>
</header>
EOF

echo "✅ Patch appliqué : le bouton 'Admin' n'apparaît que si user.roles contient 'admin' (desktop + mobile)."
