import { Injectable } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SupabaseImageService {
  private supabase: SupabaseClient | null = null;
  private bucketName = 'places-images';

  constructor() {
    const sbUrl = (environment as any).supabaseUrl;
    const sbKey = (environment as any).supabaseKey;

    if (sbUrl && sbKey && !sbUrl.includes('votre-projet')) {
      this.supabase = createClient(sbUrl, sbKey);
      console.log('✅ Supabase initialisé avec succès.');
    } else {
      console.warn('⚠️ Supabase non configuré ou clés par défaut détectées.');
    }
  }

  async uploadImage(file: File, path: string): Promise<string | null> {
    if (!this.supabase) {
      throw new Error('Supabase client non initialisé. Vérifiez environment.ts');
    }

    // 1. Upload
    console.log(`📤 Upload vers ${this.bucketName}/${path}...`);
    const { data, error } = await this.supabase.storage
      .from(this.bucketName)
      .upload(path, file, { upsert: true });

    if (error) {
      console.error('❌ Erreur Upload Supabase:', error);
      throw error;
    }

    // 2. Get Public URL
    const { data: publicUrlData } = this.supabase.storage
      .from(this.bucketName)
      .getPublicUrl(path);
    
    const finalUrl = publicUrlData.publicUrl;
    console.log('✅ Image uploadée:', finalUrl);
    
    return finalUrl;
  }
}
