import { Injectable, inject } from '@angular/core';
import { Auth, authState, GoogleAuthProvider, signInWithPopup, signOut, User as FirebaseUser } from '@angular/fire/auth';
import { Firestore, doc, setDoc, getDoc } from '@angular/fire/firestore';
import { Observable, of, from } from 'rxjs';
import { switchMap, map } from 'rxjs/operators';
import { User } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  // Injection directe des services modulaires
  private auth: Auth = inject(Auth);
  private firestore: Firestore = inject(Firestore);

  user$: Observable<User | null | undefined>;

  constructor() {
    // authState() est la version modulaire de afAuth.authState
    this.user$ = authState(this.auth).pipe(
      switchMap((user: FirebaseUser | null) => {
        if (!user) {
          return of(null);
        }

        const userDocRef = doc(this.firestore, `users/${user.uid}`);
        return from(getDoc(userDocRef)).pipe(
          map((snap) => {
            if (!snap.exists()) {
              return null;
            }
            return {
              uid: user.uid,
              ...(snap.data() as any)
            } as User;
          })
        );
      })
    );
  }

  // Connexion Google (Promise)
  async googleSignin(): Promise<void> {
    const provider = new GoogleAuthProvider();
    try {
      const credential = await signInWithPopup(this.auth, provider);
      await this.updateUserData(credential.user);
    } catch (error) {
      console.error("Erreur AuthService (Modulaire):", error);
      throw error;
    }
  }

  // Déconnexion
  async signOut(): Promise<void> {
    await signOut(this.auth);
  }

  // Mise à jour des données utilisateur
  private async updateUserData(user: FirebaseUser): Promise<void> {
    const userDocRef = doc(this.firestore, `users/${user.uid}`);
    
    const data: User = {
      uid: user.uid,
      email: user.email || '',
      displayName: user.displayName || '',
      roles: ['admin'], // Attention : merge: true protège les données existantes
      createdAt: new Date()
    };

    // setDoc avec { merge: true } remplace userRef.set(..., { merge: true })
    await setDoc(userDocRef, data, { merge: true });
  }
}
