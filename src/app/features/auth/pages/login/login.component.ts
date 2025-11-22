import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  isLoading = false;
  errorMessage = '';
  debugInfo = ''; // Ajout pour voir l'erreur brute

  constructor(private auth: AuthService, private router: Router) {}

  async loginWithGoogle() {
    this.isLoading = true;
    this.errorMessage = '';
    this.debugInfo = '';
    
    try {
      console.log('Tentative de connexion Google...');
      await this.auth.googleSignin();
      console.log('Connexion réussie !');
      this.router.navigate(['/']);
    } catch (err: any) {
      console.error('Erreur login détaillée:', err);
      
      // Affichage de l'erreur brute pour le développeur
      this.debugInfo = JSON.stringify(err, null, 2);
      
      if (err.code === 'auth/popup-closed-by-user') {
        this.errorMessage = "Connexion annulée par l'utilisateur.";
      } else if (err.code === 'auth/configuration-not-found') {
        this.errorMessage = "Google Auth n'est pas activé dans la console Firebase.";
      } else if (err.code === 'auth/unauthorized-domain') {
        this.errorMessage = "Le domaine localhost n'est pas autorisé dans Firebase Auth.";
      } else {
        this.errorMessage = "Erreur : " + (err.message || "Inconnue");
      }
    } finally {
      this.isLoading = false;
    }
  }
}
