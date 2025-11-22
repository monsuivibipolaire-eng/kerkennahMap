import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app/app.routes';
import { importProvidersFrom } from '@angular/core';

// Nouveaux imports Firebase (Modulaires)
import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';

// On garde FIREBASE_OPTIONS pour la compatibilité si besoin, mais on privilégie la nouvelle méthode
import { FIREBASE_OPTIONS } from '@angular/fire/compat';

import { environment } from './environments/environment';

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes, withComponentInputBinding()),

    // Initialisation Firebase Modulaire (Recommandée pour Standalone)
    provideFirebaseApp(() => initializeApp(environment.firebaseConfig)),
    provideAuth(() => getAuth()),
    provideFirestore(() => getFirestore()),

    // Provider de compatibilité (Pour que votre AuthService existant continue de marcher avec 'compat')
    { provide: FIREBASE_OPTIONS, useValue: environment.firebaseConfig }
  ]
}).catch(err => console.error(err));
