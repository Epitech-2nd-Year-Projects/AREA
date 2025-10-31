'use client'

import * as React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail
} from '@/components/ui/sidebar'
import {
  LinkIcon,
  LogsIcon,
  NotebookTextIcon,
  ShieldUserIcon
} from 'lucide-react'
import { UserRole } from '@/lib/api/contracts/users'
import { useTranslations } from 'next-intl'
import { UserDropdown } from './user-dropdown'
import { useCurrentUserQuery, mapUserDTOToUser } from '@/lib/api/openapi/auth'

type NavItem = {
  internationalizedTitle: string
  href: string
  icon?: React.ReactNode
}

type NavGroup = {
  internationalizedTitle: string
  allowedRoles?: UserRole[]
  items: NavItem[]
}

const navData: {
  navMain: NavGroup[]
} = {
  navMain: [
    {
      internationalizedTitle: 'admin',
      allowedRoles: [UserRole.Admin],
      items: [
        {
          internationalizedTitle: 'adminLogs',
          href: '/dashboard/admin/logs',
          icon: <LogsIcon />
        },
        {
          internationalizedTitle: 'adminUsers',
          href: '/dashboard/admin/users',
          icon: <ShieldUserIcon />
        }
      ]
    },
    {
      internationalizedTitle: 'myArea',
      allowedRoles: [UserRole.Admin, UserRole.Member],
      items: [
        {
          internationalizedTitle: 'services',
          href: '/dashboard',
          icon: <NotebookTextIcon />
        },
        {
          internationalizedTitle: 'links',
          href: '/dashboard/links',
          icon: <LinkIcon />
        }
      ]
    }
  ]
}

function canAccessGroup(userRole: UserRole, groupRoles?: UserRole[]) {
  if (!groupRoles) return true
  const groupRole = groupRoles.find((role) => role === userRole)
  return groupRole !== undefined
}

export function DashboardSidebar(props: React.ComponentProps<typeof Sidebar>) {
  const t = useTranslations('Sidebar')
  const pathname = usePathname()
  const { data, isLoading } = useCurrentUserQuery()
  const user = data?.user ? mapUserDTOToUser(data.user) : null
  const effectiveRole = user?.role ?? UserRole.Member

  return (
    <Sidebar {...props}>
      <SidebarHeader></SidebarHeader>
      <SidebarContent>
        {navData.navMain
          .filter((group) => canAccessGroup(effectiveRole, group.allowedRoles))
          .map((group) => (
            <SidebarGroup key={group.internationalizedTitle}>
              <SidebarGroupLabel>
                {t(group.internationalizedTitle)}
              </SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {group.items.map((item) => {
                    const isActive = pathname === item.href
                    return (
                      <SidebarMenuItem key={item.internationalizedTitle}>
                        <SidebarMenuButton asChild isActive={isActive}>
                          <Link href={item.href}>
                            {item.icon}
                            {t(item.internationalizedTitle)}
                          </Link>
                        </SidebarMenuButton>
                      </SidebarMenuItem>
                    )
                  })}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          ))}
      </SidebarContent>
      <SidebarFooter>
        {user && !isLoading ? <UserDropdown user={user} /> : null}
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  )
}
