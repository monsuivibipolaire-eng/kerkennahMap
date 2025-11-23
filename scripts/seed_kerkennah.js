const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp'); // ✅ AJOUT : pour compresser/redimensionner les images

// =============================================================================
// 1. CONFIGURATION
// =============================================================================

const SUPABASE_URL = 'https://bcuxfuqgwoqyammgmpjw.supabase.co';
const SUPABASE_KEY = 'sb_secret_GnRXdBMwhJqpO4LZGKfwKg_HbVpIYjh';
const BUCKET_NAME = process.env.BUCKET_NAME || 'places-images';

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Manque serviceAccountKey.json dans le dossier du script.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// =============================================================================
// 2. CHARGER LE JSON KERKENNAH_LIEUX_REELLES
// =============================================================================

const jsonPath = path.join(__dirname, 'kerkennah_lieux.json');
if (!fs.existsSync(jsonPath)) {
  console.error('❌ Manque kerkennah_lieux_reelles.json dans le dossier du script.');
  process.exit(1);
}

const kerkennahLieux = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
console.log(`✅ Chargé ${kerkennahLieux.length} lieux depuis kerkennah_lieux_reelles.json\n`);

// =============================================================================
// 3. TRANSFORMER LE JSON EN FORMAT COMPATIBLE AVEC FIRESTORE
// =============================================================================

function transformLieuToPlace(lieu) {
  const slug = lieu.id;
  
  return {
    slug,
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
// 4. FONCTION POUR TÉLÉCHARGER + COMPRESSER UNE IMAGE
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
      headers: {
        'User-Agent': 'Kerkennah-Map-Bot (kerkennah.app)'
      },
      timeout: 30000
    });

    // ✅ 1) On récupère le buffer original
    const originalBuffer = Buffer.from(response.data);

    // ✅ 2) On COMPRESSE + REDIMENSIONNE avant upload
    // - rotate() : corrige orientation EXIF
    // - resize() : max 1600px de large, sans agrandir les petites images
    // - jpeg({ quality: 70 }) : baisse la qualité (70% ~ très correct visuellement)
    const optimizedBuffer = await sharp(originalBuffer)
      .rotate()
      .resize({
        width: 1600,
        withoutEnlargement: true
      })
      .jpeg({
        quality: 70,
        mozjpeg: true
      })
      .toBuffer();

    const fileName = randomFileName(placeSlug);
    const { error: uploadError } = await supabase
      .storage
      .from(BUCKET_NAME)
      .upload(fileName, optimizedBuffer, {
        contentType: 'image/jpeg',
        cacheControl: '31536000', // optionnel mais bon pour les perfs
        upsert: false
      });

    if (uploadError) {
      console.error('      ❌ Erreur upload Supabase:', uploadError.message);
      throw uploadError;
    }

    const { data } = supabase.storage.from(BUCKET_NAME).getPublicUrl(fileName);
    console.log(`      ✅ Upload OK (compressé)`);
    return data.publicUrl;
  } catch (err) {
    console.error(`      ⚠️ Erreur: ${err.message}`);
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
    createdAt: new Date(),
    createdBy: 'kerkennah_seed_real_images'
  };

  await db.collection('places').doc(place.slug).set(payload, { merge: false });
}

// =============================================================================
// 6. SCRIPT PRINCIPAL
// =============================================================================

async function run() {
  console.log(`🚀 Démarrage Seed Kerkennah (${places.length} lieux)...\n`);

  let successCount = 0;
  let errorCount = 0;
  let totalImages = 0;
  let uploadedImages = 0;

  for (const place of places) {
    try {
      console.log(`\n=== ${place.name} [${place.slug}] ===`);

      const imagesUrls = [];

      // Télécharger toutes les images du lieu (6 par défaut)
      if (place.imageUrls && place.imageUrls.length > 0) {
        for (let i = 0; i < place.imageUrls.length; i++) {
          const url = place.imageUrls[i];
          totalImages++;
          const publicUrl = await downloadImageFromUrl(place.slug, url, i + 1);
          
          if (publicUrl) {
            imagesUrls.push(publicUrl);
            uploadedImages++;
          }
          
          // Petit délai entre les téléchargements
          if (i < place.imageUrls.length - 1) {
            await new Promise(resolve => setTimeout(resolve, 400));
          }
        }
      } else {
        console.warn(`   ⚠️ Aucune image pour ce lieu`);
      }

      if (imagesUrls.length === 0) {
        console.warn(`   ⚠️ Aucune image n'a pu être téléchargée`);
      }

      // Créer le document Firestore
      await createPlaceDoc(place, imagesUrls);
      console.log(`   ✅ Document Firestore créé (${imagesUrls.length}/${place.imageUrls.length} images)`);
      successCount++;
    } catch (err) {
      console.error(`   ❌ Erreur: ${err.message}`);
      errorCount++;
    }

    // Délai entre chaque lieu
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  console.log(`\n${'='.repeat(60)}`);
  console.log(`🎉 Seed Kerkennah terminé !`);
  console.log(`${'='.repeat(60)}`);
  console.log(`✅ Lieux importés: ${successCount}/${places.length}`);
  console.log(`❌ Erreurs: ${errorCount}/${places.length}`);
  console.log(`📸 Images uploadées: ${uploadedImages}/${totalImages}`);
  
  if (errorCount === 0 && uploadedImages > 0) {
    console.log(`\n✨ Tous les lieux ont été importés avec succès !`);
    console.log(`📍 ${successCount} lieux avec ${uploadedImages} images réelles\n`);
  }
}

run().catch((err) => {
  console.error('❌ Erreur globale seed:', err);
  process.exit(1);
});
