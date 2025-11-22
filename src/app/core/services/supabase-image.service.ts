import { Injectable } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SupabaseImageService {
  private supabase: SupabaseClient | null = null;

  constructor() {
    const sbUrl = (environment as any).supabaseUrl;
    const sbKey = (environment as any).supabaseKey;

    if (sbUrl && sbKey && sbUrl !== 'https://votre-projet.supabase.co') {
      this.supabase = createClient(sbUrl, sbKey);
    } else {
      console.warn('Supabase non configuré. L\'upload d\'images ne fonctionnera pas.');
    }
  }

  async uploadImage(file: File, path: string): Promise<string | null> {
    if (!this.supabase) {
      console.error('Impossible d\'uploader : Supabase n\'est pas initialisé.');
      return null;
    }

    const { data, error } = await this.supabase.storage
      .from('places-images')
      .upload(path, file);

    if (error) {
      console.error('Supabase Upload Error:', error);
      return null;
    }

    const { data: publicUrlData } = this.supabase.storage
      .from('places-images')
      .getPublicUrl(path);
      
    return publicUrlData.publicUrl;
  }
}
