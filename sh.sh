#!/usr/bin/env sh
set -e

HEADER_HTML="src/app/core/components/header/header.component.html"

echo "=== Fix template HeaderComponent (TS2571 + Parser Error) ==="

if [ -f "$HEADER_HTML" ]; then
  echo "-> Réécriture de $HEADER_HTML"

  cat > "$HEADER_HTML" << 'EOF'
<header class="flex items-center justify-between px-4 py-2 bg-blue-900 text-white">
  <div class="text-2xl">
    🏝️ <span class="font-semibold">Mon Application</span>
  </div>

  <div class="flex items-center gap-2">
    <ng-container *ngIf="user$ | async as u; else loginBlock">
      <span class="text-sm text-gray-200">Connecté en tant que</span>
      <span class="font-semibold text-sm">
        {{ $any(u)?.displayName || $any(u)?.email }}
      </span>
    </ng-container>

    <ng-template #loginBlock>
      <a
        routerLink="/login"
        class="px-3 py-1 rounded-full bg-white text-blue-900 text-sm font-medium"
      >
        Se connecter
      </a>
    </ng-template>
  </div>
</header>
EOF

else
  echo "⚠️ Fichier introuvable : $HEADER_HTML"
fi

echo "=== Terminé. Relance 'ng serve' ==="
