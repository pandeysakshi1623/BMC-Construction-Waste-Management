import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ItemsComponent } from './items/items.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, ItemsComponent],
  template: `
    <div style="padding: 20px;">
      <h1>Posts from JSONPlaceholder API</h1>
      <app-items></app-items>
    </div>
  `,
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'angular-api-experiment';
}
