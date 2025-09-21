<script setup lang="ts">
const config = useRuntimeConfig()
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')
const okMsg = ref('')
const router = useRouter()

const onSubmit = async () => {
  errorMsg.value = ''
  okMsg.value = ''
  loading.value = true
  try {
    const { error } = await useFetch('/auth', {
      baseURL: config.public.apiBase,
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: { email: email.value, password: password.value }
    })
    if (error.value) {
      const status = (error.value as any)?.status || 0
      errorMsg.value = status === 401 ? 'Invalid credentials' : 'Login error'
      return
    }
    okMsg.value = 'Signed in'
    setTimeout(() => router.push('/'), 600)
  } catch (e) {
    errorMsg.value = 'Network error'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="mx-auto max-w-md px-6 py-10 md:px-8">
    <h1 class="text-2xl font-semibold">Sign in</h1>
    <form @submit.prevent="onSubmit" class="mt-4 grid gap-3">
      <label class="grid gap-1">
        <div class="text-sm font-medium text-gray-700">Email</div>
        <input
          v-model="email"
          type="email"
          required
          placeholder="yoursupercoolemail@example.com"
          class="block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder:text-gray-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </label>
      <label class="grid gap-1">
        <div class="text-sm font-medium text-gray-700">Password</div>
        <input
          v-model="password"
          type="password"
          required
          minlength="8"
          placeholder="your super omega strong password"
          class="block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder:text-gray-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </label>
      <button
        :disabled="loading"
        class="mt-1 inline-flex items-center justify-center rounded-md bg-blue-600 px-4 py-2 text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-60"
      >
        {{ loading ? 'Signing in…' : 'Sign in' }}
      </button>
      <p v-if="errorMsg" class="text-sm text-red-600">{{ errorMsg }}</p>
      <p v-if="okMsg" class="text-sm text-green-700">{{ okMsg }}</p>
    </form>

    <p class="mt-4 text-sm text-gray-700">
      No account?
      <NuxtLink to="/register" class="text-blue-600 hover:underline">Create an account</NuxtLink>
    </p>
  </main>
</template>
