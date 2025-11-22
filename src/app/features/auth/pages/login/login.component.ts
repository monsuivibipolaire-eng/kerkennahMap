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

  constructor(private auth: AuthService, private router: Router) {}

  async loginWithGoogle() {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      await this.auth.googleSignin();
      // Redirection vers l'accueil après succès
      this.router.navigate(['/']);
    } catch (err: any) {
      console.error('Erreur login:', err);
      this.errorMessage = "Une erreur est survenue lors de la connexion avec Google.";
      if (err.code === 'auth/popup-closed-by-user') {
        this.errorMessage = "Connexion annulée par l'utilisateur.";
      }
    } finally {
      this.isLoading = false;
    }
  }
}
