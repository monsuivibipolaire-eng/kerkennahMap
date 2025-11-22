import { Injectable } from '@angular/core';
import { AngularFirestore, AngularFirestoreCollection } from '@angular/fire/compat/firestore';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Place } from '../models/place.model';

@Injectable({
  providedIn: 'root'
})
export class PlacesService {
  private placesCollection: AngularFirestoreCollection<Place>;

  constructor(private afs: AngularFirestore) {
    // Initialisation de la collection 'places'
    this.placesCollection = this.afs.collection<Place>('places');
  }

  // Récupérer tous les lieux approuvés
  getApprovedPlaces(): Observable<Place[]> {
    return this.afs.collection<Place>('places', ref => ref.where('status', '==', 'approved'))
      .valueChanges({ idField: 'id' });
  }

  // Récupérer un lieu par son ID
  getPlaceById(id: string): Observable<Place | undefined> {
    return this.placesCollection.doc<Place>(id).valueChanges({ idField: 'id' });
  }

  // Ajouter un nouveau lieu
  addPlace(place: Place): Promise<any> {
    const id = this.afs.createId();
    return this.placesCollection.doc(id).set({ ...place, id });
  }

  // Admin: Récupérer les lieux en attente
  getPendingPlaces(): Observable<Place[]> {
    return this.afs.collection<Place>('places', ref => ref.where('status', '==', 'pending'))
      .valueChanges({ idField: 'id' });
  }
}
