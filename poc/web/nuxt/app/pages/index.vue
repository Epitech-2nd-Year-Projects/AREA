<template>
  <main class="mx-auto max-w-md px-6 py-10 md:px-8">
    <h1 class="text-3xl font-semibold tracking-tight">AREA Nuxt PoC</h1>
    <p class="mt-2 text-gray-600">Welcome to try our API authentication</p>

    <nav class="mt-6 flex gap-3">
      <NuxtLink
        to="/login"
        class="inline-flex items-center justify-center rounded-md bg-blue-600 px-4 py-2 text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
      >
        Sign in
      </NuxtLink>
      <NuxtLink
        to="/register"
        class="inline-flex items-center justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
      >
        Create an account
      </NuxtLink>
    </nav>
  </main>
  
</template>
