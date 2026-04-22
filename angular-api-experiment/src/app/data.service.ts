import { Injectable } from '@angular/core';

export interface Post {
  id: number;
  title: string;
  body: string;
}

@Injectable({
  providedIn: 'root'
})
export class DataService {
  private apiUrl = 'https://jsonplaceholder.typicode.com/posts?_limit=10';

  async getPosts(): Promise<Post[]> {
    try {
      const response = await fetch(this.apiUrl);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const posts: Post[] = await response.json();
      return posts;
    } catch (error) {
      console.error('Error fetching posts:', error);
      return [];
    }
  }
}
