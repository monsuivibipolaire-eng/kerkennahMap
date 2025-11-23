// scripts/add_missing_place_images.js

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import admin from 'firebase-admin';
import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ====== CONFIG ======

const MAX_IMAGES = 5; // nombre d'images souhaité par place
const FIREBASE_SERVICE_ACCOUNT_PATH =
  process.env.FIREBASE_SERVICE_ACCOUNT ||
  path.join(__dirname, 'serviceAccountKey.json');

const SUPABASE_URL = 'https://bcuxfuqgwoqyammgmpjw.supabase.co'
const SUPABASE_SERVICE_ROLE_KEY = 'sb_secret_GnRXdBMwhJqpO4LZGKfwKg_HbVpIYjh';
// Nom du bucket Supabase où tu stockes les images
const SUPABASE_BUCKET = 'places-images';

// ===================== VALIDATION CONFIG =====================

if (!fs.existsSync(FIREBASE_SERVICE_ACCOUNT_PATH)) {
  console.error('❌ serviceAccountKey.json introuvable :', FIREBASE_SERVICE_ACCOUNT_PATH);
  process.exit(1);
}

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquants dans les variables d’environnement');
  process.exit(1);
}

const serviceAccount = JSON.parse(
  fs.readFileSync(FIREBASE_SERVICE_ACCOUNT_PATH, 'utf-8')
);

// ===================== INITIALISATION FIREBASE =====================

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
}

const db = admin.firestore();

// ===================== INITIALISATION SUPABASE =====================

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// ===================== FONCTIONS UTILITAIRES =====================

async function searchWikimediaImages(query, limit = 5) {
  // On cherche des fichiers (namespace=6) liés au nom de la place
  const encoded = encodeURIComponent(query);
  const url =
    `https://commons.wikimedia.org/w/api.php` +
    `?action=query&generator=search&gsrnamespace=6&gsrlimit=${limit}` +
    `&gsrsearch=${encoded}` +
    `&prop=imageinfo&iiprop=url&format=json&origin=*`;

  const res = await fetch(url);
  if (!res.ok) {
    console.error('❌ Erreur Wikimedia:', res.status, res.statusText);
    return [];
  }

  const data = await res.json();
  if (!data.query || !data.query.pages) return [];

  const pages = Object.values(data.query.pages);
  const images = [];

  for (const page of pages) {
    if (page.imageinfo && page.imageinfo[0] && page.imageinfo[0].url) {
      images.push({
        url: page.imageinfo[0].url,
        title: page.title,
      });
    }
  }

  return images;
}

async function uploadToSupabaseFromUrl(placeId, imageUrl, index = 0) {
  const res = await fetch(imageUrl);

  if (!res.ok) {
    console.error(`   ❌ Impossible de télécharger l'image ${imageUrl}: ${res.status}`);
    return null;
  }

  const arrayBuffer = await res.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  const contentType = res.headers.get('content-type') || 'image/jpeg';

  const extension = contentType.includes('png')
    ? 'png'
    : contentType.includes('webp')
    ? 'webp'
    : 'jpg';

  const filename = `places/${placeId}/${Date.now()}_${index}.${extension}`;

  const { data, error } = await supabase.storage
    .from(SUPABASE_BUCKET)
    .upload(filename, buffer, {
      contentType,
      upsert: false,
    });

  if (error) {
    console.error('   ❌ Erreur upload Supabase:', error.message);
    return null;
  }

  const { data: publicData } = supabase.storage
    .from(SUPABASE_BUCKET)
    .getPublicUrl(data.path);

  return publicData.publicUrl;
}

// ===================== LOGIQUE PRINCIPALE =====================

async function main() {
  console.log('🚀 Complétion des images Firestore à partir de Wikimedia + Supabase');

  const snapshot = await db.collection('places').get();
  console.log(`📚 ${snapshot.size} places trouvées`);

  let updatedCount = 0;

  for (const doc of snapshot.docs) {
    const place = doc.data();
    const placeId = doc.id;
    const name = place.name || place.title || placeId;

    const images = Array.isArray(place.images) ? place.images : [];
    const currentCount = images.length;

    if (currentCount >= MAX_IMAGES) {
      console.log(`- ${name} (${placeId}) a déjà ${currentCount} images ✅`);
      continue;
    }

    const missing = MAX_IMAGES - currentCount;
    console.log(`- ${name} (${placeId}) n'a que ${currentCount} images → il en manque ${missing}`);

    // On ajoute "Kerkennah" pour cibler la zone
    const searchQuery = `${name} Kerkennah`;

    const candidates = await searchWikimediaImages(searchQuery, missing * 2);
    if (!candidates.length) {
      console.log('   ⚠️ Aucune image trouvée sur Wikimedia pour', searchQuery);
      continue;
    }

    const newUrls = [];

    for (let i = 0; i < candidates.length && newUrls.length < missing; i++) {
      const img = candidates[i];
      console.log(`   🔎 Image candidate: ${img.url}`);

      try {
        const publicUrl = await uploadToSupabaseFromUrl(placeId, img.url, i);
        if (publicUrl) {
          console.log(`   ✅ Upload OK → ${publicUrl}`);
          newUrls.push(publicUrl);
        }
      } catch (err) {
        console.error('   ❌ Erreur pendant traitement d’image:', err.message || err);
      }
    }

    if (!newUrls.length) {
      console.log('   ⚠️ Aucune nouvelle image uploadée pour cette place');
      continue;
    }

    const updatedImages = [...images, ...newUrls];

    try {
      await db.collection('places').doc(placeId).update({
        images: updatedImages,
      });
      console.log(`   💾 Firestore mis à jour (${updatedImages.length} images au total)`);
      updatedCount++;
    } catch (err) {
      console.error('   ❌ Erreur mise à jour Firestore:', err.message || err);
    }
  }

  console.log(`✅ Terminé. ${updatedCount} places mises à jour.`);
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Erreur fatale:', err);
  process.exit(1);
});
