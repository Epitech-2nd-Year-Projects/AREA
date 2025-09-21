import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html'
})
export class LoginComponent {
  loading = false;
  error: string | null = null;
  success = false;

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  constructor(private fb: FormBuilder, private auth: AuthService) { }

  submit() {
    if (this.form.invalid) return;
    this.loading = true;
    this.error = null;
    this.success = false;

    const { email, password } = this.form.getRawValue();
    this.auth.login({ email: email!, password: password! }).subscribe({
      next: () => {
        this.success = true;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.message || 'Login failed';
      },
    });
  }
}

