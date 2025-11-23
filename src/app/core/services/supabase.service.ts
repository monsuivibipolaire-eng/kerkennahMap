import { Injectable } from '@angular/core';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable({
  providedIn: 'root'
})
export class SupabaseService {
  private supabase: SupabaseClient;

  constructor() {
    this.supabase = createClient(
      'https://bcuxfuqgwoqyammgmpjw.supabase.co', 
      'sb_secret_GnRXdBMwhJqpO4LZGKfwKg_HbVpIYjh'
    );
  }

  async uploadImage(file: File): Promise<string> {
    const timestamp = Date.now();
    const cleanName = file.name.replace(/[^a-z0-9]/gi, '_');
    const fileName = `place_${timestamp}_${cleanName}`;
    
    const { data, error } = await this.supabase.storage
      .from('places')
      .upload(fileName, file, { 
        cacheControl: '3600',
        upsert: false 
      });
    
    if (error) {
      throw new Error(`Upload failed: ${error.message}`);
    }
    
    const { data: urlData } = this.supabase.storage
      .from('places')
      .getPublicUrl(fileName);
    
    return urlData.publicUrl;
  }
}
