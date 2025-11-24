import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PlacesService } from '../../../../core/services/places.service';
import { Place } from '../../../../core/models/place.model';

@Component({
  selector: 'app-admin-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './admin-list.component.html',
  styles: [`
    .card { @apply bg-white rounded-lg shadow p-6 mb-4; }
    .btn-seed { @apply bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 transition; }
  `]
})
export class AdminListComponent {
  private placesService = inject(PlacesService);
  
  isLoading = false;
  message = '';

  // Données statiques à injecter
  kerkennahPlaces: Partial<Place>[] = [
    {
      name: "Borj El Hissar",
      description: "Ancien fort hispano-turc situé près de Sidi Fredj. Un site historique incontournable offrant une vue imprenable sur la mer.",
      latitude: 34.7089,
      longitude: 11.1644,
      categories: ["Histoire", "Tourisme"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Borj_El_Hissar_-_Kerkennah_-_Tunisie.jpg/800px-Borj_El_Hissar_-_Kerkennah_-_Tunisie.jpg"]
    },
    {
      name: "Musée du Patrimoine Insulaire (Sidi Abbes)",
      description: "Un musée fascinant à El Abbassia qui retrace l'histoire, les traditions et le mode de vie unique des habitants de l'archipel.",
      latitude: 34.7255,
      longitude: 11.2485,
      categories: ["Culture", "Musée"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Mus%C3%A9e_du_patrimoine_insulaire_de_Kerkennah_04.jpg/800px-Mus%C3%A9e_du_patrimoine_insulaire_de_Kerkennah_04.jpg"]
    },
    {
      name: "Port de Sidi Youssef",
      description: "Le point d'entrée principal de l'archipel via le ferry (Loud). Un lieu vivant où l'on prend le pouls de l'île.",
      latitude: 34.6542,
      longitude: 10.9987,
      categories: ["Transport", "Port"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Arriv%C3%A9e_du_bac_%C3%A0_Sidi_Youssef_01.jpg/800px-Arriv%C3%A9e_du_bac_%C3%A0_Sidi_Youssef_01.jpg"]
    },
    {
      name: "Plage de Sidi Fredj",
      description: "Une des plages les plus populaires, idéale pour la baignade et les couchers de soleil spectaculaires.",
      latitude: 34.7050,
      longitude: 11.1500,
      categories: ["Plage", "Détente"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Plage_de_Sidi_Fekhri_01.jpg/800px-Plage_de_Sidi_Fekhri_01.jpg"] // Image générique plage
    },
    {
      name: "Grand Hôtel Kerkennah",
      description: "Un hôtel historique situé les pieds dans l'eau à Sidi Fredj, connu pour son architecture typique.",
      latitude: 34.7065,
      longitude: 11.1520,
      categories: ["Hôtel", "Restaurant"],
      status: "approved",
      images: ["https://dynamic-media-cdn.tripadvisor.com/media/photo-o/12/04/25/8e/grand-hotel-kerkennah.jpg?w=1200&h=-1&s=1"]
    },
    {
      name: "Site Archéologique de Kerkouane (Similaire)",
      description: "Ruines antiques témoignant du passé punique et romain de l'archipel (Cercina).",
      latitude: 34.6900,
      longitude: 11.1200,
      categories: ["Histoire", "Ruines"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Ruines_romaines_%C3%A0_Kerkennah.jpg/800px-Ruines_romaines_%C3%A0_Kerkennah.jpg"]
    },
    {
      name: "Village de Remla",
      description: "Le chef-lieu administratif de l'archipel. On y trouve le marché, la poste et l'animation locale.",
      latitude: 34.7130,
      longitude: 11.1950,
      categories: ["Ville", "Commerce"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Remla_centre_ville.jpg/800px-Remla_centre_ville.jpg"]
    },
    {
      name: "Port de Pêche El Attaya",
      description: "Un village de pêcheurs authentique à la pointe nord. Célèbre pour ses techniques de pêche traditionnelles (Charfia).",
      latitude: 34.7450,
      longitude: 11.2800,
      categories: ["Pêche", "Authentique"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Port_d%27El_Attaya_02.jpg/800px-Port_d%27El_Attaya_02.jpg"]
    },
    {
      name: "Restaurant Le Sirene",
      description: "Spécialités de fruits de mer frais pêchés localement. Une institution culinaire.",
      latitude: 34.7070,
      longitude: 11.1550,
      categories: ["Restaurant", "Gastronomie"],
      status: "approved",
      images: ["https://media-cdn.tripadvisor.com/media/photo-s/1a/43/6e/58/terrasse.jpg"]
    },
    {
      name: "Archipel des îlots inhabités",
      description: "Excursion en bateau vers les îlots sauvages autour de Gremdi. Nature préservée.",
      latitude: 34.7600,
      longitude: 11.3000,
      categories: ["Nature", "Aventure"],
      status: "approved",
      images: ["https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Kerkennah_Paysage.jpg/800px-Kerkennah_Paysage.jpg"]
    }
  ];

  async seedDatabase() {
    if (!confirm('Voulez-vous vraiment injecter ces 10 lieux dans Firebase ?')) return;
    
    this.isLoading = true;
    this.message = 'Injection en cours...';
    let count = 0;

    try {
      for (const place of this.kerkennahPlaces) {
        // On ajoute un créateur fictif 'System'
        const data = { ...place, createdBy: 'system_seeder', createdAt: new Date() } as Place;
        await this.placesService.addPlace(data);
        count++;
      }
      this.message = `✅ Succès ! ${count} lieux ajoutés. Allez voir la carte !`;
    } catch (err) {
      console.error(err);
      this.message = '❌ Erreur lors de l\'injection.';
    } finally {
      this.isLoading = false;
    }
  }
}
