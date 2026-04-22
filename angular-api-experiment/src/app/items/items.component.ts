import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DataService, Post } from '../data.service';

@Component({
  selector: 'app-items',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './items.component.html',
  styleUrls: ['./items.component.css']
})
export class ItemsComponent implements OnInit {
  posts: Post[] = [];

  constructor(private dataService: DataService) {}

  async ngOnInit() {
    this.posts = await this.dataService.getPosts();
  }

  trackById(index: number, post: Post): number {
    return post.id;
  }
}
