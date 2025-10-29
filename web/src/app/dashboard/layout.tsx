import * as React from 'react'
import { redirect } from 'next/navigation'
import { Separator } from '@/components/ui/separator'
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger
} from '@/components/ui/sidebar'
import { DashboardSidebar } from '@/components/dashboard/dashboard-sidebar'
import DynamicBreadcrumb from '@/components/dashboard/dynamic-breadcrumb'
import { currentUserServer } from '@/lib/api/openapi/auth/server'

export default async function DashboardLayout({
  children
}: {
  children: React.ReactNode
}) {
  try {
    await currentUserServer()
  } catch {
    redirect('/login')
  }

  return (
    <SidebarProvider>
      <DashboardSidebar />
      <SidebarInset>
        <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4">
          <SidebarTrigger className="-ml-1" />
          <Separator
            orientation="vertical"
            className="mr-2 data-[orientation=vertical]:h-4"
          />
          <DynamicBreadcrumb
            basePath="/dashboard"
            rootLabel="Dashboard"
            titleMap={{
              statistics: 'Statistics',
              messages: 'Messages'
            }}
          />
        </header>
        <div className="p-4">{children}</div>
      </SidebarInset>
    </SidebarProvider>
  )
}
