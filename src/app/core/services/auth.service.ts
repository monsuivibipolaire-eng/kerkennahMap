import { Injectable } from '@angular/core';
import { AngularFireAuth } from '@angular/fire/compat/auth';
import { AngularFirestore } from '@angular/fire/compat/firestore';
import { Observable, of } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { User } from '../models/user.model';
import firebase from 'firebase/compat/app';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  user$: Observable<User | null | undefined>;

  constructor(
    private afAuth: AngularFireAuth,
    private afs: AngularFirestore
  ) {
    // Observe l'état de l'utilisateur et récupère ses données Firestore correspondantes
    this.user$ = this.afAuth.authState.pipe(
      switchMap(user => {
        if (user) {
          return this.afs.doc<User>(`users/${user.uid}`).valueChanges();
        } else {
          return of(null);
        }
      })
    );
  }

  // Connexion Google
  async googleSignin() {
    const provider = new firebase.auth.GoogleAuthProvider();
    const credential = await this.afAuth.signInWithPopup(provider);
    return this.updateUserData(credential.user);
  }

  // Déconnexion
  async signOut() {
    await this.afAuth.signOut();
  }

  // Met à jour les données utilisateur dans Firestore après connexion
  private updateUserData(user: firebase.User | null) {
    if (!user) return;
    const userRef = this.afs.doc(`users/${user.uid}`);
    
    const data: User = {
      uid: user.uid,
      email: user.email || '',
      displayName: user.displayName || '',
      roles: ['user'], // Par défaut. À changer manuellement en BDD pour admin
      createdAt: new Date()
    };

    return userRef.set(data, { merge: true });
  }
}
