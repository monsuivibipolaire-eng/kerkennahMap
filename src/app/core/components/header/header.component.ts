import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './header.component.html'
})
export class HeaderComponent implements OnInit {

  user$ : any = null;

  constructor(private authService: AuthService) {}

  ngOnInit() {
    // Assignation après que le constructor ait injecté authService
    this.user$ = this.authService.user$;
  }
}
