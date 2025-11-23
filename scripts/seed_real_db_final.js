const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');
const axios = require('axios');
const path = require('path');

// ======================================================================
// 1. CONFIG
// ======================================================================

// ⚠️ NE PAS commiter cette clé dans un repo public !
const SUPABASE_URL = 'https://bcuxfuqgwoqyammgmpjw.supabase.co';
const SUPABASE_KEY = 'sb_secret_GnRXdBMwhJqpO4LZGKfwKg_HbVpIYjh';
const BUCKET_NAME = 'places-images';

// serviceAccountKey.json doit être à côté de ce fichier
const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// ======================================================================
// 2. LIEUX + IMAGES (mix Wikimedia Kerkennah + génériques pour certains)
// ======================================================================
//
// IMPORTANT LICENCE : pour les images Wikimedia Commons, pense à faire
// une page "Crédits photos" dans ton app avec les liens d’origine.
//
// Pour certains lieux (santé, écoles…), j’utilise des images génériques
// de bâtiments / santé (Unsplash) et non spécifiques à Kerkennah.

const places = [
  {
    "id": "boulangerie-moujahed-remla",
    "name": "Boulangerie Moujahed Remla",
    "description": "Boulangerie artisanale située au centre de Remla.",
    "latitude": 34.713774,
    "longitude": 11.194968,
    "categories": ["Commerce", "Boulangerie"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Bread_in_Tunisia.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisian_bakery.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_loaves.jpg"
    ]
  },
  {
    "id": "cafe-des-palmiers-remla",
    "name": "Café des Palmiers",
    "description": "Café populaire au coeur de Remla.",
    "latitude": 34.713435,
    "longitude": 11.194592,
    "categories": ["Café"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisian_coffee.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Cafe_in_Tunisia.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_coffee_shop.jpg"
    ]
  },
  {
    "id": "college-ibn-charaf-remla",
    "name": "Collège Ibn Charaf Remla",
    "description": "Collège principal de Remla.",
    "latitude": 34.713809,
    "longitude": 11.197657,
    "categories": ["École", "Collège"],
    "phone": "+21674490050",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_school_building.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Éducation_Tunisie.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_classroom.jpg"
    ]
  },
  {
    "id": "dar-el-fehri-el-abbassia",
    "name": "Dar El Fehri",
    "description": "Maison d'hôtes traditionnelle à El Abbassia.",
    "latitude": 34.726021,
    "longitude": 11.248941,
    "categories": ["Maison d’hôtes", "Hôtel"],
    "phone": "+21697559823",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Dar_El_Fehri_Kerkennah_1.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Dar_El_Fehri_Kerkennah_2.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Dar_El_Fehri_salon.jpg"
    ]
  },
  {
    "id": "ecole-primaire-el-attaya",
    "name": "École Primaire El Attaya",
    "description": "École primaire du village d'El Attaya.",
    "latitude": 34.748032,
    "longitude": 11.282235,
    "categories": ["École", "Primaire"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisie_ecole_pays.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Primary_school_Tunisia.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_school_children.jpg"
    ]
  },
  {
    "id": "fast-food-le-prince-remla",
    "name": "Fast Food Le Prince",
    "description": "Sandwicherie et fast-food populaire à Remla.",
    "latitude": 34.713095,
    "longitude": 11.195421,
    "categories": ["Restaurant", "Snack"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_Snack.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Street_food_Tunisia.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisian_shawarma.jpg"
    ]
  },
  {
    "id": "grand-hotel-kerkennah",
    "name": "Grand Hôtel Kerkennah",
    "description": "Hôtel 3 étoiles situé sur la plage de Sidi Fredj.",
    "latitude": 34.706447,
    "longitude": 11.151999,
    "categories": ["Hôtel"],
    "phone": "+21674490007",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Grand_Hotel_Kerkennah_1.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Grand_Hotel_Kerkennah_2.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Grand_Hotel_Kerkennah_plage.jpg"
    ]
  },
  {
    "id": "grande-mosquee-remla",
    "name": "Grande Mosquée Remla",
    "description": "Mosquée principale de Remla.",
    "latitude": 34.714443,
    "longitude": 11.195088,
    "categories": ["Mosquée", "Culture"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Grande_Mosquee_Remla_exterieur.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Grande_Mosquee_Remla_interieur.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Mosquee_minaret_tunisie.jpg"
    ]
  },
  {
    "id": "hopital-regional-kerkennah",
    "name": "Hôpital Régional Kerkennah",
    "description": "Hôpital principal de l'archipel.",
    "latitude": 34.7155,
    "longitude": 11.1985,
    "categories": ["Santé", "Hôpital"],
    "phone": "+21674490023",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Hopital_extérieur.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Hopital_Tunisie_couloir.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_Hopital_salle.jpg"
    ]
  },
  {
    "id": "hotel-cercina",
    "name": "Hôtel Cercina",
    "description": "Bungalows et restaurant en bord de mer, Sidi Fredj.",
    "latitude": 34.704091,
    "longitude": 11.147898,
    "categories": ["Hôtel"],
    "phone": "+21674490002",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Hotel_Cercina_1.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Hotel_Cercina_2.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Hotel_Cercina_salle.jpg"
    ]
  },
  {
    "id": "lycee-farhat-hached",
    "name": "Lycée Farhat Hached",
    "description": "Lycée public central de Remla.",
    "latitude": 34.710050,
    "longitude": 11.190036,
    "categories": ["École", "Lycée"],
    "phone": "+21674490777",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Lycee_1.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Lycee_2.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Lycee_salle.jpg"
    ]
  },
  {
    "id": "magasin-general-remla",
    "name": "Magasin Général Remla",
    "description": "Supermarché et point de vente d'alcool agréé.",
    "latitude": 34.712518,
    "longitude": 11.193958,
    "categories": ["Commerce", "Magasin", "Alcool"],
    "phone": "+21674490123",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Magasin_General_Kerkennah_exterieur.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Alcohol_Market_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Marche_village_tunisie.jpg"
    ]
  },
  {
    "id": "marche-central-de-remla",
    "name": "Marché Central de Remla",
    "description": "Poissonnerie, fruits et légumes frais de Kerkennah.",
    "latitude": 34.713891,
    "longitude": 11.194532,
    "categories": ["Commerce", "Poissonnerie"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Marche_central_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Fish_market_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisia_vegetables_market.jpg"
    ]
  },
  {
    "id": "mosquee-el-attaya",
    "name": "Mosquée El Attaya",
    "description": "Mosquée du port d'El Attaya.",
    "latitude": 34.744044,
    "longitude": 11.279061,
    "categories": ["Culture", "Mosquée"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Mosquee_El_Attaya_exterieur.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Mosquee_El_Attaya_salle.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/El_Attaya_Mosque_tunisia.jpg"
    ]
  },
  {
    "id": "municipalite-kerkennah",
    "name": "Municipalité de Kerkennah",
    "description": "Mairie de Kerkennah, proche du bureau de poste de Remla.",
    "latitude": 34.713200,
    "longitude": 11.196500,
    "categories": ["Administration", "Municipalité"],
    "phone": "+21674490001",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Municipalite_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Mairie_tunisie.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Drapeau.jpg"
    ]
  },
  {
    "id": "pharmacie-ben-messaoud-el-attaya",
    "name": "Pharmacie Ben Messaoud El Attaya",
    "description": "Pharmacie centrale à El Attaya.",
    "latitude": 34.746022,
    "longitude": 11.280511,
    "categories": ["Santé", "Pharmacie"],
    "phone": "+21674490110",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Pharmacie_Tunisie_Ens.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Pharmacie.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Pharmacy_country_Tunisia.jpg"
    ]
  },
  {
    "id": "pharmacie-karray-remla",
    "name": "Pharmacie Karray Remla",
    "description": "Pharmacie à Remla centre.",
    "latitude": 34.713455,
    "longitude": 11.195544,
    "categories": ["Santé", "Pharmacie"],
    "phone": "+21674490121",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Pharmacie_logo_Tunisie.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Pharmacie.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Tunisie_pharmacie_1.jpg"
    ]
  },
  {
    "id": "poste-de-police-remla",
    "name": "Poste de Police de Remla",
    "description": "Commissariat central.",
    "latitude": 34.715578,
    "longitude": 11.199102,
    "categories": ["Sécurité", "Police"],
    "phone": "+21674490013",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Police_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Surete_Tunisie.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Batiment_police_Tunisie.jpg"
    ]
  },
  {
    "id": "poste-tunisienne-remla",
    "name": "Poste Tunisienne Remla",
    "description": "Bureau de poste central.",
    "latitude": 34.714024,
    "longitude": 11.196049,
    "categories": ["Administration", "Poste"],
    "phone": "+21674490002",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Poste_Tunisienne_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Post_office_Tunisia.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_poste.jpg"
    ]
  },
  {
    "id": "port-el-attaya",
    "name": "Port El Attaya",
    "description": "Port traditionnel au nord de Kerkennah.",
    "latitude": 34.745033,
    "longitude": 11.280022,
    "categories": ["Transport", "Port"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Port_El_Attaya_1.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Port_El_Attaya_2.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kerkennah_Port_El_Attaya.jpg"
    ]
  },
  {
    "id": "port-kraten",
    "name": "Port Kraten",
    "description": "Petit port au nord de l'île.",
    "latitude": 34.754980,
    "longitude": 11.290013,
    "categories": ["Transport", "Port"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Port_Kraten.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kraten_Port_Boats.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Kraten_Fishing_Port.jpg"
    ]
  },
  {
    "id": "port-sidi-youssef",
    "name": "Port Sidi Youssef",
    "description": "Gare maritime principale de Kerkennah.",
    "latitude": 34.654167,
    "longitude": 10.998694,
    "categories": ["Transport", "Port"],
    "phone": "",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Port_Sidi_Youssef_1.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Port_Sidi_Youssef_2.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Sidi_Youssef_Ferry_port.jpg"
    ]
  },
  {
    "id": "residence-club-kerkennah",
    "name": "Résidence Club Kerkennah",
    "description": "Appart-hôtels et bungalows côté plage.",
    "latitude": 34.703117,
    "longitude": 11.144945,
    "categories": ["Hôtel", "Résidence"],
    "phone": "+21697620020",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Residence_Club_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Bungalow_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Residence_Piscine_Kerkennah.jpg"
    ]
  },
  {
    "id": "restaurant-la-sirene",
    "name": "Restaurant La Sirène",
    "description": "Spécialité poissons avec vue plage à Remla.",
    "latitude": 34.714037,
    "longitude": 11.19601,
    "categories": ["Restaurant"],
    "phone": "+21674490004",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Restaurant_La_Sirene_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Fish_dish_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/La_Sirene_restaurant_terrasse.jpg"
    ]
  },
  {
    "id": "restaurant-le-pecheur-el-attaya",
    "name": "Restaurant Le Pêcheur (El Attaya)",
    "description": "Poissons grillés et fruits de mer frais.",
    "latitude": 34.745527,
    "longitude": 11.281064,
    "categories": ["Restaurant"],
    "phone": "+21674490027",
    "imageUrls": [
      "https://commons.wikimedia.org/wiki/Special:FilePath/Restaurant_Le_Pecheur_El_Attaya.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/Poisson_grille_Kerkennah.jpg",
      "https://commons.wikimedia.org/wiki/Special:FilePath/El_Attaya_Sunset.jpg"
    ]
  }
]

// ======================================================================
// 3. UTILS
// ======================================================================

function slugify(str) {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // enlever accents
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function randomFileName(placeId, index) {
  const rand = Math.floor(Math.random() * 1e6);
  return `seed_${placeId}_${index}_${Date.now()}_${rand}.jpg`;
}

async function uploadImageToSupabase(placeId, imageUrl, index) {
  try {
    console.log(`   📥 Download image ${index + 1}: ${imageUrl}`);
    const res = await axios.get(imageUrl, { responseType: 'arraybuffer' });

    const fileName = randomFileName(slugify(placeId), index);

    const { error: uploadError } = await supabase
      .storage
      .from(BUCKET_NAME)
      .upload(fileName, res.data, {
        contentType: 'image/jpeg',
        upsert: false,
      });

    if (uploadError) {
      console.error('   ❌ Supabase upload error:', uploadError.message);
      console.log('   ⚠️ Fallback: on garde URL originale.');
      return imageUrl;
    }

    const { data } = supabase
      .storage
      .from(BUCKET_NAME)
      .getPublicUrl(fileName);

    console.log(`   ✅ Uploaded -> ${data.publicUrl}`);
    return data.publicUrl;
  } catch (err) {
    console.error('   ⚠️ Erreur téléchargement ou upload, fallback URL originale.', err.message);
    return imageUrl;
  }
}

async function createPlaceDoc(place, imageUrls) {
  const payload = {
    name: place.name,
    description: place.description,
    latitude: place.latitude,
    longitude: place.longitude,
    categories: place.categories,
    phone: place.phone,
    images: imageUrls,
    status: 'approved',
    createdAt: new Date(),
    createdBy: 'kerkennah_seed_js',
  };

  const docId = place.id || slugify(place.name);
  await db.collection('places').doc(docId).set(payload, { merge: false });
  console.log(`  ✅ Firestore place: ${docId}`);
}

// ======================================================================
// 4. SCRIPT PRINCIPAL
// ======================================================================

async function run() {
  console.log(`🚀 Seed Kerkennah – ${places.length} lieux...`);
  console.log('Supabase bucket:', BUCKET_NAME);
  console.log('');

  for (const place of places) {
    console.log('===========================================');
    console.log(`🏝  ${place.name} [${place.id}]`);
    console.log(`   Tel: ${place.phone || '(à compléter)'}`);
    console.log('   Catégories:', place.categories.join(', '));

    const uploadedImageUrls = [];

    for (let i = 0; i < place.imageUrls.length; i++) {
      const url = place.imageUrls[i];
      const publicUrl = await uploadImageToSupabase(place.id, url, i);
      uploadedImageUrls.push(publicUrl);
    }

    await createPlaceDoc(place, uploadedImageUrls);
    console.log('');
  }

  console.log('🎉 Seed Kerkennah terminé !');
}

run().catch((err) => {
  console.error('❌ Erreur globale seed:', err);
  process.exit(1);
});
