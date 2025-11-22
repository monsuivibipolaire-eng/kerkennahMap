/**
 * Script d'administration pour définir le rôle 'admin' sur un utilisateur Firebase.
 * Utilisation : node scripts/setAdmin.js <email>
 */

const admin = require('firebase-admin');
const path = require('path');

// 1. Récupération de l'argument (email)
const args = process.argv.slice(2);
if (args.length !== 1) {
  console.error('Usage : node scripts/setAdmin.js <email-utilisateur>');
  process.exit(1);
}
const userEmail = args[0];

// 2. Chargement de la clé de service
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

try {
  // On vérifie si le fichier existe
  const serviceAccount = require(serviceAccountPath);

  // 3. Initialisation
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  console.log(`Recherche de l'utilisateur : ${userEmail}...`);

  // 4. Recherche et attribution
  admin.auth().getUserByEmail(userEmail)
    .then((user) => {
      return admin.auth().setCustomUserClaims(user.uid, { admin: true })
        .then(() => {
          console.log('--------------------------------------------------');
          console.log('✅ SUCCÈS !');
          console.log(`L'utilisateur ${userEmail} (UID: ${user.uid}) est maintenant ADMIN.`);
          // Correction ici : échappement de l'apostrophe (L\'utilisateur)
          console.log('NOTE : L\'utilisateur doit se déconnecter et se reconnecter pour que le changement prenne effet.');
          console.log('--------------------------------------------------');
          process.exit(0);
        });
    })
    .catch((error) => {
      console.error('❌ ERREUR :', error.message);
      process.exit(1);
    });

} catch (error) {
  if (error.code === 'MODULE_NOT_FOUND') {
    console.error('❌ ERREUR CRITIQUE : Fichier serviceAccountKey.json introuvable !');
    console.error('Veuillez placer votre clé privée dans le dossier scripts/.');
  } else {
    console.error('Erreur inattendue :', error);
  }
  process.exit(1);
}
