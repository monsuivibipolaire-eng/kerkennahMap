	#!/bin/bash

# Nom du fichier de sortie
OUTPUT_FILE="project_src_concatenated.txt"

# 1. Nettoyer l'ancien fichier s'il existe
> $OUTPUT_FILE

echo "Démarrage de la concatenation des fichiers de 'src/'..."

# 2. Trouver et parcourir tous les fichiers dans le répertoire 'src/'
#    -mindepth 1 : assure que nous ne traitons pas le répertoire 'src/' lui-même
#    -type f : s'assure de ne traiter que les fichiers (et non les dossiers)
#    -print0 et xargs -0 : méthode sûre pour gérer les noms de fichiers contenant des espaces
find src/ -mindepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
    
    # 3. Ajouter un en-tête pour identifier le fichier
    echo "==================================================" >> $OUTPUT_FILE
    echo "FICHIER: $file" >> $OUTPUT_FILE
    echo "==================================================" >> $OUTPUT_FILE
    
    # 4. Ajouter le contenu du fichier
    cat "$file" >> $OUTPUT_FILE
    
    # 5. Ajouter un saut de ligne pour la séparation
    echo -e "\n" >> $OUTPUT_FILE
    
    echo "Ajouté : $file"
done

echo "--------------------------------------------------"
echo "✅ Concatenation terminée. Tous les fichiers se trouvent dans : $OUTPUT_FILE"
