'use client'

import { Bell, ChevronsUpDown, HomeIcon, LogOut, Settings } from 'lucide-react'

import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'
import {
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar
} from '@/components/ui/sidebar'
import type { User } from '@/lib/api/contracts/users'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { useLogoutMutation } from '@/lib/api/openapi/auth'
import { useRouter } from 'next/navigation'
import { LanguageSwitcher } from '@/components/ui/language-switcher'
import { AnimatedThemeToggler } from '@/components/ui/animated-theme-toggler'

function getUserAvatarFallback(user: User) {
  return user.email.slice(0, 2).toUpperCase()
}

export function UserDropdown({ user }: { user: User }) {
  const t = useTranslations('SidebarUserNavigation')
  const { isMobile } = useSidebar()
  const router = useRouter()
  const { mutate: logout } = useLogoutMutation()

  const handleLogout = () => {
    logout(undefined, {
      onSuccess: () => {
        router.push('/login')
      }
    })
  }

  return (
    <SidebarMenu>
      <SidebarMenuItem>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <SidebarMenuButton
              size="lg"
              className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground"
            >
              <Avatar className="h-8 w-8 rounded-lg">
                <AvatarImage src={user.imageUrl ?? ''} alt={'No image'} />
                <AvatarFallback className="rounded-lg">
                  {getUserAvatarFallback(user)}
                </AvatarFallback>
              </Avatar>
              <div className="grid flex-1 text-left text-sm leading-tight">
                <span className="truncate text-xs">{user.email}</span>
              </div>
              <ChevronsUpDown className="ml-auto size-4" />
            </SidebarMenuButton>
          </DropdownMenuTrigger>
          <DropdownMenuContent
            className="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg"
            side={isMobile ? 'bottom' : 'right'}
            align="end"
            sideOffset={4}
          >
            <DropdownMenuLabel className="p-0 font-normal">
              <div className="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                <Avatar className="h-8 w-8 rounded-lg">
                  <AvatarImage src={user.imageUrl ?? ''} alt={'No image'} />
                  <AvatarFallback className="rounded-lg">
                    {getUserAvatarFallback(user)}
                  </AvatarFallback>
                </Avatar>
                <div className="grid flex-1 text-left text-sm leading-tight">
                  <span className="truncate text-xs">{user.email}</span>
                </div>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <div className="flex items-center justify-between gap-2 px-2 py-1.5">
              <LanguageSwitcher className="flex-1 justify-center" />
              <AnimatedThemeToggler className="rounded-md border border-border/40 p-2 transition hover:border-border" />
            </div>
            <DropdownMenuSeparator />
            <DropdownMenuGroup>
              <DropdownMenuItem>
                <Settings />
                <Link href="/dashboard/profile">{t('profile')}</Link>
              </DropdownMenuItem>
              <DropdownMenuItem>
                <Bell />
                <Link href="/dashboard/notifications">
                  {t('notifications')}
                </Link>
              </DropdownMenuItem>
            </DropdownMenuGroup>
            <DropdownMenuSeparator />
            <DropdownMenuItem>
              <HomeIcon />
              <Link href="/">{t('backToHome')}</Link>
            </DropdownMenuItem>
            <DropdownMenuItem onClick={handleLogout} className="cursor-pointer">
              <LogOut />
              <span>{t('logout')}</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </SidebarMenuItem>
    </SidebarMenu>
  )
}
