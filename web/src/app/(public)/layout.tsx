import { PublicNavbar } from '@/components/public-navbar'

export default function PublicLayout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-svh flex flex-col">
      <PublicNavbar />
      <main className="flex-1 p-16">{children}</main>
    </div>
  )
}
