import * as React from 'react'

import { Separator } from '@/components/ui/separator'
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger
} from '@/components/ui/sidebar'
import { DashboardSidebar } from '@/components/dashboard/dashboard-sidebar'
import DynamicBreadcrumb from '@/components/dashboard/dynamic-breadcrumb'

export default async function DashboardLayout({
  children
}: {
  children: React.ReactNode
}) {
  // TODO: Check if user is logged in, redirect accordingly

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
        {children}
      </SidebarInset>
    </SidebarProvider>
  )
}
