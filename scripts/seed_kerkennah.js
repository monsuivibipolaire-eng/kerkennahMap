console.log('🚀 seed_kerkennah.js – version debug 1');

const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

// =============================================================================
// 1. CONFIGURATION ET AUTHENTIFICATION (CORRIGÉ)
// =============================================================================

const SUPABASE_URL = 'https://bcuxfuqgwoqyammgmpjw.supabase.co';
const SUPABASE_KEY = 'sb_secret_GnRXdBMwhJqpO4LZGKfwKg_HbVpIYjh'; // ⚠️ Attention, ne jamais commiter ceci dans un repo public
const BUCKET_NAME = process.env.BUCKET_NAME || 'places-images';

// Chargement robuste de la clé de service
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`❌ ERREUR CRITIQUE: Le fichier serviceAccountKey.json est introuvable ici : ${serviceAccountPath}`);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

// Initialisation Firebase avec forcage du projectId pour éviter l'erreur UNAUTHENTICATED
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id // ✅ On force explicitement l'ID du projet
  });
}

const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// =============================================================================
// 2. CHARGER LE JSON
// =============================================================================

const jsonPath = path.join(__dirname, 'kerkennah_lieux.json');
if (!fs.existsSync(jsonPath)) {
  console.error('❌ Manque kerkennah_lieux.json dans le dossier du script.');
  process.exit(1);
}

const kerkennahLieux = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
console.log(`✅ Chargé ${kerkennahLieux.length} lieux depuis kerkennah_lieux.json\n`);

// =============================================================================
// 3. TRANSFORMER LE JSON
// =============================================================================

function transformLieuToPlace(lieu) {
  return {
    slug: lieu.id,
    name: lieu.name,
    desc: lieu.description,
    lat: lieu.latitude,
    lng: lieu.longitude,
    cats: lieu.categories,
    phone: lieu.phone || '',
    imageUrls: lieu.imageUrls || []
  };
}

const places = kerkennahLieux.map(transformLieuToPlace);

// =============================================================================
// 4. FONCTION DOWNLOAD + UPLOAD
// =============================================================================

function randomFileName(slug) {
  const rand = Math.floor(Math.random() * 1e6);
  return `seed_${slug}_${Date.now()}_${rand}.jpg`;
}

async function downloadImageFromUrl(placeSlug, imageUrl, imageIndex) {
  try {
    console.log(`   📥 Image ${imageIndex}: ${imageUrl.substring(0, 60)}...`);
    
    const response = await axios.get(imageUrl, { 
      responseType: 'arraybuffer',
      headers: { 'User-Agent': 'Kerkennah-Map-Bot' },
      timeout: 30000
    });

    const originalBuffer = Buffer.from(response.data);

    const optimizedBuffer = await sharp(originalBuffer)
      .rotate()
      .resize({ width: 1600, withoutEnlargement: true })
      .jpeg({ quality: 70, mozjpeg: true })
      .toBuffer();

    const fileName = randomFileName(placeSlug);
    const { error: uploadError } = await supabase
      .storage
      .from(BUCKET_NAME)
      .upload(fileName, optimizedBuffer, {
        contentType: 'image/jpeg',
        cacheControl: '31536000',
        upsert: false
      });

    if (uploadError) throw uploadError;

    const { data } = supabase.storage.from(BUCKET_NAME).getPublicUrl(fileName);
    console.log(`      ✅ Upload OK`);
    return data.publicUrl;
  } catch (err) {
    console.error(`      ⚠️ Erreur image: ${err.message}`);
    return null;
  }
}

// =============================================================================
// 5. CRÉER LE DOCUMENT FIRESTORE
// =============================================================================

async function createPlaceDoc(place, imagesUrls) {
  const payload = {
    name: place.name,
    description: place.desc,
    latitude: place.lat,
    longitude: place.lng,
    categories: place.cats,
    phone: place.phone,
    status: 'approved',
    images: imagesUrls.filter(url => url !== null),
    createdAt: admin.firestore.Timestamp.now(), // ✅ Utilisation du timestamp natif Firestore
    createdBy: 'kerkennah_seed_real_images'
  };

  await db.collection('places').doc(place.slug).set(payload, { merge: true });
}

// =============================================================================
// 6. SCRIPT PRINCIPAL
// =============================================================================

async function run() {
  console.log(`🚀 Démarrage Seed Kerkennah (${places.length} lieux)...\n`);

  let successCount = 0;
  let errorCount = 0;

  for (const place of places) {
    try {
      console.log(`\n=== ${place.name} [${place.slug}] ===`);
      const imagesUrls = [];

      if (place.imageUrls?.length > 0) {
        for (let i = 0; i < place.imageUrls.length; i++) {
          const url = await downloadImageFromUrl(place.slug, place.imageUrls[i], i + 1);
          if (url) imagesUrls.push(url);
          if (i < place.imageUrls.length - 1) await new Promise(r => setTimeout(r, 400));
        }
      }

      await createPlaceDoc(place, imagesUrls);
      console.log(`   ✅ Firestore OK (${imagesUrls.length} images)`);
      successCount++;
    } catch (err) {
      console.error(`   ❌ Erreur Firestore: ${err.message}`);
      errorCount++;
    }
    await new Promise(r => setTimeout(r, 1000));
  }

  console.log(`\nTerminé: ${successCount} succès, ${errorCount} erreurs.`);
}

run().catch((err) => {
  console.error('❌ Erreur globale seed:', err);
  process.exit(1);
});
