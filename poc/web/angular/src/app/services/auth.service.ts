import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { Observable } from 'rxjs';

export interface Credentials {
  email: string;
  password: string;
}

export interface AuthResponse {
  userId?: string;
  email?: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private baseUrl = environment.apiBaseUrl;

  constructor(private http: HttpClient) { }

  login(body: Credentials): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.baseUrl}/auth`, body, {
      withCredentials: true,
    });
  }

  register(body: Credentials): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.baseUrl}/register`, body, {
      withCredentials: true,
    });
  }
}

