const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ serviceAccountKey.json introuvable :', serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

const db = admin.firestore();

(async () => {
  try {
    console.log('🔎 Project ID:', serviceAccount.project_id);
    await db.collection('test_seed').doc('ping').set({
      now: new Date().toISOString(),
    });
    console.log('✅ Écriture Firestore OK');
    process.exit(0);
  } catch (err) {
    console.error('❌ Erreur Firestore test:', err.code, err.message);
    process.exit(1);
  }
})();
