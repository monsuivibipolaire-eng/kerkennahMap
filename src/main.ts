import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app/app.routes';
import { provideAnimations } from '@angular/platform-browser/animations'; // <-- AJOUT IMPORTANT

// Imports Firebase
import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';
import { FIREBASE_OPTIONS } from '@angular/fire/compat';
import { environment } from './environments/environment';
import * as L from 'leaflet';

// Configuration des icônes Leaflet
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'assets/leaflet/marker-icon-2x.png',
  iconUrl: 'assets/leaflet/marker-icon.png',
  shadowUrl: 'assets/leaflet/marker-shadow.png'
});

bootstrapApplication(AppComponent, {
  providers: [
    // 👇 C'est cette ligne qui corrige l'erreur NG05105
    provideAnimations(),
    
    provideRouter(routes, withComponentInputBinding()),

    // Initialisation Firebase
    provideFirebaseApp(() => initializeApp(environment.firebaseConfig)),
    provideAuth(() => getAuth()),
    provideFirestore(() => getFirestore()),

    // Provider de compatibilité
    { provide: FIREBASE_OPTIONS, useValue: environment.firebaseConfig }
  ]
}).catch(err => console.error(err));
