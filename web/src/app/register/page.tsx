import { RegisterForm } from '@/components/authentication/register-form'

export default function RegisterPage() {
  return (
    <div className="bg-muted flex min-h-svh flex-col items-center justify-center p-6 md:p-10">
      <div className="max-w-sm md:max-w-3xl">
        <RegisterForm />
      </div>
    </div>
  )
}
