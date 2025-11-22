import { Injectable, inject } from '@angular/core';
import { Firestore, collection, collectionData, doc, docData, addDoc, query, where } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Place } from '../models/place.model';

@Injectable({
  providedIn: 'root'
})
export class PlacesService {
  private firestore: Firestore = inject(Firestore);

  constructor() {}

  // Récupérer tous les lieux approuvés
  getApprovedPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'approved'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }

  // Récupérer un lieu par son ID
  getPlaceById(id: string): Observable<Place | undefined> {
    const placeDocRef = doc(this.firestore, `places/${id}`);
    return docData(placeDocRef, { idField: 'id' }) as Observable<Place>;
  }

  // Ajouter un nouveau lieu
  addPlace(place: Place): Promise<any> {
    const placesRef = collection(this.firestore, 'places');
    return addDoc(placesRef, place);
  }

  // Admin: Récupérer les lieux en attente
  getPendingPlaces(): Observable<Place[]> {
    const placesRef = collection(this.firestore, 'places');
    const q = query(placesRef, where('status', '==', 'pending'));
    return collectionData(q, { idField: 'id' }) as Observable<Place[]>;
  }
}
