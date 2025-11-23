const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// --- 1. CONFIGURATION (A REMPLIR) ---
const SUPABASE_URL = 'https://votre-projet.supabase.co'; 
const SUPABASE_KEY = 'votre-cle-service-role'; 
const BUCKET_NAME = 'places-images';

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error("❌ Manque 'scripts/serviceAccountKey.json'"); process.exit(1);
}
const serviceAccount = require(serviceAccountPath);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// --- 2. BANQUE D'IMAGES THÉMATIQUES (Unsplash - Stable & Gratuit) ---
const imagesBank = {
  // Santé
  hopital: [
    "https://images.unsplash.com/photo-1587351021759-3e566b9af6f2?w=800&q=80", // Hôpital
    "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80", // Salle attente
    "https://images.unsplash.com/photo-1516549655169-df83a0926e97?w=800&q=80"  // Médecin
  ],
  pharmacie: [
    "https://images.unsplash.com/photo-1585435557343-3b092031a831?w=800&q=80", // Croix verte
    "https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800&q=80", // Médicaments
    "https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800&q=80"  // Comptoir
  ],
  // Éducation
  ecole: [
    "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&q=80", // Salle classe
    "https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=800&q=80", // École ext
    "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&q=80"  // Élèves
  ],
  // Admin
  poste: [
    "https://images.unsplash.com/photo-1579621970563-ebec7560eb3e?w=800&q=80", // Courrier
    "https://images.unsplash.com/photo-1622151834677-70f982c9adef?w=800&q=80", // Guichet
    "https://images.unsplash.com/photo-1596526131083-e8c633c948d2?w=800&q=80"  // Bureau
  ],
  police: [
    "https://images.unsplash.com/photo-1455382054916-9c94e985343d?w=800&q=80", // Police
    "https://images.unsplash.com/photo-1555852995-6c629793e67e?w=800&q=80", // Voiture
    "https://images.unsplash.com/photo-1485230905346-71acb9518d9c?w=800&q=80"  // Badge
  ],
  mairie: [
    "https://images.unsplash.com/photo-1577962917302-cd874c4e31d2?w=800&q=80", // Mairie
    "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800&q=80", // Drapeau
    "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80"  // Bureau
  ],
  // Tourisme
  hotel: [
    "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80",
    "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80",
    "https://images.unsplash.com/photo-1496417263034-38ec4f0d665a?w=800&q=80"
  ],
  restaurant: [
    "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80",
    "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80",
    "https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=800&q=80"
  ],
  cafe: [
    "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80",
    "https://images.unsplash.com/photo-1511081692775-05d0f180a065?w=800&q=80",
    "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=800&q=80"
  ],
  plage: [
    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80",
    "https://images.unsplash.com/photo-1519046904884-53103b34b271?w=800&q=80",
    "https://images.unsplash.com/photo-1473186578172-c141e6798cf4?w=800&q=80"
  ],
  mosquee: [
    "https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=800&q=80", // Mosquée
    "https://images.unsplash.com/photo-1564121211835-e88c852648ab?w=800&q=80", // Intérieur
    "https://images.unsplash.com/photo-1542042956712-cdb2a4b85a1a?w=800&q=80"  // Minaret
  ]
};

// Fonction pour récupérer 3 images selon la catégorie
function getImages(cats) {
  const cat = cats[0].toLowerCase();
  let key = 'ville'; // défaut

  if (cat.includes('hôpital') || cat.includes('santé')) key = 'hopital';
  else if (cat.includes('pharmacie')) key = 'pharmacie';
  else if (cat.includes('école') || cat.includes('lycée') || cat.includes('collège')) key = 'ecole';
  else if (cat.includes('poste')) key = 'poste';
  else if (cat.includes('police') || cat.includes('garde')) key = 'police';
  else if (cat.includes('mairie') || cat.includes('municipalité')) key = 'mairie';
  else if (cat.includes('mosquée')) key = 'mosquee';
  else if (cat.includes('restaurant')) key = 'restaurant';
  else if (cat.includes('hôtel')) key = 'hotel';
  else if (cat.includes('café')) key = 'cafe';
  else if (cat.includes('plage')) key = 'plage';

  return (imagesBank[key] || imagesBank.ville).slice(0, 3);
}

// --- 3. DONNÉES RÉELLES KERKENNAH (Liste Étendue) ---
const places = [
  // SANTÉ
  { name: "Hôpital Régional de Kerkennah", desc: "Service d'urgences et soins généraux.", lat: 34.7150, lng: 11.1980, cats: ["Santé", "Hôpital"] },
  { name: "Pharmacie de Nuit Remla", desc: "Pharmacie de garde.", lat: 34.7135, lng: 11.1955, cats: ["Santé", "Pharmacie"] },
  { name: "Dispensaire El Attaya", desc: "Soins de base.", lat: 34.7460, lng: 11.2810, cats: ["Santé"] },
  { name: "Pharmacie Centrale Mellita", desc: "Pharmacie principale du village.", lat: 34.6810, lng: 11.0820, cats: ["Santé", "Pharmacie"] },

  // ÉDUCATION
  { name: "Lycée Farhat Hached", desc: "Lycée secondaire principal.", lat: 34.7100, lng: 11.1900, cats: ["École", "Lycée"] },
  { name: "Collège Remla", desc: "Enseignement moyen.", lat: 34.7120, lng: 11.1920, cats: ["École", "Collège"] },
  { name: "École Primaire El Attaya", desc: "École du village.", lat: 34.7470, lng: 11.2820, cats: ["École"] },
  { name: "Collège Mellita", desc: "Collège mixte.", lat: 34.6790, lng: 11.0780, cats: ["École", "Collège"] },

  // ADMINISTRATION & SERVICES
  { name: "Bureau de Poste Remla", desc: "Poste centrale.", lat: 34.7140, lng: 11.1960, cats: ["Administration", "Poste"] },
  { name: "Municipalité de Kerkennah", desc: "Hôtel de ville.", lat: 34.7130, lng: 11.1970, cats: ["Administration", "Mairie"] },
  { name: "Poste de Police Remla", desc: "Sécurité publique.", lat: 34.7155, lng: 11.1990, cats: ["Administration", "Police"] },
  { name: "Garde Nationale Sidi Youssef", desc: "Contrôle portuaire.", lat: 34.6540, lng: 10.9990, cats: ["Administration", "Police"] },
  { name: "STEG Kerkennah", desc: "Agence d'électricité.", lat: 34.7110, lng: 11.1930, cats: ["Administration"] },
  { name: "SONEDE Kerkennah", desc: "Agence des eaux.", lat: 34.7115, lng: 11.1935, cats: ["Administration"] },

  // RELIGION
  { name: "Grande Mosquée de Remla", desc: "Lieu de culte principal.", lat: 34.7145, lng: 11.1950, cats: ["Culture", "Mosquée"] },
  { name: "Mosquée El Attaya", desc: "Mosquée du port.", lat: 34.7440, lng: 11.2790, cats: ["Culture", "Mosquée"] },
  { name: "Mosquée Sidi Fredj", desc: "Petite mosquée côtière.", lat: 34.7060, lng: 11.1510, cats: ["Culture", "Mosquée"] },

  // TOURISME & LOISIRS (Rappel)
  { name: "Grand Hôtel Kerkennah", desc: "Hôtel historique.", lat: 34.7065, lng: 11.1520, cats: ["Hôtel"] },
  { name: "Hôtel Cercina", desc: "Bungalows bord de mer.", lat: 34.7040, lng: 11.1480, cats: ["Hôtel"] },
  { name: "Restaurant Le Pêcheur", desc: "Spécialité poissons.", lat: 34.7455, lng: 11.2810, cats: ["Restaurant"] },
  { name: "Restaurant La Sirène", desc: "Vue mer.", lat: 34.7140, lng: 11.1960, cats: ["Restaurant"] },
  { name: "Plage Sidi Fredj", desc: "Baignade familiale.", lat: 34.7050, lng: 11.1500, cats: ["Plage"] },
  { name: "Café des Palmiers", desc: "Café populaire.", lat: 34.7135, lng: 11.1945, cats: ["Café"] }
];

// --- 4. GÉNÉRATION DE REMPLISSAGE (Commerces & Cafés locaux) ---
const zones = [
  { n: "Remla", lat: 34.713, lng: 11.195 }, 
  { n: "Mellita", lat: 34.680, lng: 11.080 },
  { n: "El Attaya", lat: 34.745, lng: 11.280 }
];

// On ajoute 20 petits commerces par zone
for (const z of zones) {
  for (let i=0; i<10; i++) {
    places.push({
      name: `Épicerie ${z.n} #${i+1}`, desc: "Alimentation générale.",
      lat: z.lat + (Math.random()-0.5)*0.01, lng: z.lng + (Math.random()-0.5)*0.01,
      cats: ["Commerce"]
    });
    places.push({
      name: `Café ${z.n} #${i+1}`, desc: "Café maure.",
      lat: z.lat + (Math.random()-0.5)*0.01, lng: z.lng + (Math.random()-0.5)*0.01,
      cats: ["Café"]
    });
  }
}

// --- 5. FONCTION PRINCIPALE ---
async function run() {
  console.log(`🚀 Injection de ${places.length} lieux (Public & Privé) + 3 Images/lieu...`);
  
  for (const p of places) {
    // 1. Récupération des images (URLs Unsplash)
    const imageUrls = getImages(p.cats);
    const uploadedUrls = [];

    // 2. Upload vers Supabase (si configuré)
    if (!SUPABASE_URL.includes('votre-projet')) {
      process.stdout.write(`Traitement: ${p.name} `);
      for (const url of imageUrls) {
        try {
          const res = await axios.get(url, { responseType: 'arraybuffer', timeout: 5000 });
          const fileName = `seed_${Date.now()}_${Math.floor(Math.random()*10000)}.jpg`;
          const { error } = await supabase.storage.from(BUCKET_NAME).upload(fileName, res.data, { contentType: 'image/jpeg' });
          if (!error) {
            const { data } = supabase.storage.from(BUCKET_NAME).getPublicUrl(fileName);
            uploadedUrls.push(data.publicUrl);
            process.stdout.write(".");
          }
        } catch (e) { process.stdout.write("x"); }
      }
      console.log(" OK");
    } else {
      // Mode sans upload (garde les URLs Unsplash directes)
      uploadedUrls.push(...imageUrls);
    }

    // 3. Sauvegarde Firestore
    await db.collection('places').add({
      name: p.name, description: p.desc, latitude: p.lat, longitude: p.lng,
      categories: p.cats, status: 'approved', 
      images: uploadedUrls, // Tableau de 3 images
      createdAt: new Date(), createdBy: 'ultimate_seeder'
    });
  }
  console.log("🎉 FINI ! Toute l'île est cartographiée.");
}

run();
