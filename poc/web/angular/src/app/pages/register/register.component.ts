import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html'
})
export class RegisterComponent {
  loading = false;
  error: string | null = null;
  success = false;

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  constructor(private fb: FormBuilder, private auth: AuthService) {}

  submit() {
    if (this.form.invalid) return;
    this.loading = true;
    this.error = null;
    this.success = false;

    const { email, password } = this.form.getRawValue();
    this.auth.register({ email: email!, password: password! }).subscribe({
      next: () => {
        this.success = true;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.message || 'Registration failed';
      },
    });
  }
}

