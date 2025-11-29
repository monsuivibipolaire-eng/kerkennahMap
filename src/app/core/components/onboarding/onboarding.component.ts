import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { animate, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-onboarding',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './onboarding.component.html',
  styleUrls: ['./onboarding.component.css'],
  animations: [
    trigger('fadeSlide', [
      transition(':enter', [
        style({ opacity: 0, transform: 'translateX(20px)' }),
        animate('500ms cubic-bezier(0.35, 0, 0.25, 1)', style({ opacity: 1, transform: 'translateX(0)' }))
      ]),
      transition(':leave', [
        animate('300ms ease-out', style({ opacity: 0, transform: 'translateX(-20px)' }))
      ])
    ])
  ]
})
export class OnboardingComponent implements OnInit {
  // MODIFICATION : Initialisé à 'true' par défaut pour s'afficher tout le temps
  isVisible = signal(true); 
  currentSlide = signal(0);

  slides = [
    {
      title: "Bienvenue sur Kerkennah Map",
      desc: "La plateforme interactive dédiée à l'archipel de Kerkennah. Découvrez les trésors cachés de nos îles.",
      icon: "🏝️",
      color: "from-blue-500 to-cyan-400"
    },
    {
      title: "Explorez Intelligemment",
      desc: "Trouvez facilement des restaurants, plages, sites historiques et services grâce à notre carte interactive et géolocalisée.",
      icon: "🗺️",
      color: "from-emerald-500 to-teal-400"
    },
    {
      title: "Contribuez à la Carte",
      desc: "Vous connaissez un lieu sympa ? Ajoutez-le ! Notre communauté grandit grâce à vos contributions.",
      icon: "➕",
      color: "from-orange-500 to-amber-400"
    },
    {
      title: "Donnez votre Avis",
      desc: "Notez les lieux, partagez vos photos et aidez les autres visiteurs à faire les meilleurs choix.",
      icon: "⭐",
      color: "from-purple-500 to-pink-400"
    },
    {
      title: "C'est parti !",
      desc: "Activez la géolocalisation pour une meilleure expérience. Profitez de votre visite à Kerkennah.",
      icon: "🚀",
      color: "from-indigo-600 to-blue-600"
    }
  ];

  ngOnInit() {
    // MODIFICATION : Nous avons supprimé la vérification du localStorage ici.
    // Le slider s'affichera donc systématiquement au rechargement de la page.
  }

  next() {
    if (this.currentSlide() < this.slides.length - 1) {
      this.currentSlide.update(v => v + 1);
    } else {
      this.close();
    }
  }

  skip() {
    this.close();
  }

  close() {
    // C'est ici que l'utilisateur décide de fermer le slider pour cette session
    this.isVisible.set(false);
    
    // Optionnel : On enregistre quand même l'action, au cas où vous voudriez
    // remettre la condition plus tard.
    localStorage.setItem('hasSeenOnboarding_v1', 'true');
  }
}
