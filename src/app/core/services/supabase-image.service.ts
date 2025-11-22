import { Injectable } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SupabaseImageService {
  private supabase: SupabaseClient;

  constructor() {
    // ATTENTION: Vous devrez ajouter 'supabaseUrl' et 'supabaseKey' dans votre environment.ts
    // Pour l'instant, on utilise des valeurs vides pour que ça compile sans erreur
    const sbUrl = (environment as any).supabaseUrl || '';
    const sbKey = (environment as any).supabaseKey || '';
    this.supabase = createClient(sbUrl, sbKey);
  }

  // Upload d'une image
  async uploadImage(file: File, path: string): Promise<string | null> {
    const { data, error } = await this.supabase.storage
      .from('places-images')
      .upload(path, file);

    if (error) {
      console.error('Supabase Upload Error:', error);
      return null;
    }

    // Récupération de l'URL publique
    const { data: publicUrlData } = this.supabase.storage
      .from('places-images')
      .getPublicUrl(path);
      
    return publicUrlData.publicUrl;
  }
}
