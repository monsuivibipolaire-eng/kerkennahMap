export interface Place {
  id?: string;
  name: string;
  description: string;
  latitude: number;
  longitude: number;
  categories: string[];
  images: string[]; // URLs des images stockées (ex: Supabase)
  status: 'pending' | 'approved' | 'rejected';
  createdBy: string; // UID de l'utilisateur
  createdAt: Date | any; // 'any' pour compatibilité Timestamp Firestore
  updatedAt?: Date | any;
}
