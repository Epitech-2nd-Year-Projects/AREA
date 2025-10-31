'use client'

import * as React from 'react'
import Link from 'next/link'
import Image from 'next/image'
import {
  ChevronRight,
  Menu,
  LogIn,
  UserPlus,
  LogOut,
  User,
  LayoutGrid
} from 'lucide-react'

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger
} from '@/components/ui/accordion'
import { Button } from '@/components/ui/button'
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger
} from '@/components/ui/navigation-menu'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger
} from '@/components/ui/sheet'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { AnimatedThemeToggler } from './ui/animated-theme-toggler'
import {
  useCurrentUserQuery,
  mapUserDTOToUser,
  useLogoutMutation
} from '@/lib/api/openapi/auth'
import { ApiError } from '@/lib/api/http/errors'
import { useRouter } from 'next/navigation'

type MenuItem = {
  title: string
  url: string
  description?: string
  icon?: React.ReactNode
  items?: MenuItem[]
}

type LandingNavbarProps = {
  logo?: {
    url: string
    src: string
    alt: string
    title: string
  }
  menu?: MenuItem[]
  auth?: {
    login: { title: string; url: string }
    getStarted: { title: string; url: string }
  }
  isAuthenticated?: boolean
  userName?: string
  userAvatarUrl?: string
  onLogin?: () => void
  onSignup?: () => void
  onLogout?: () => void
}

const cn = (...classes: Array<string | undefined | null | false>) =>
  classes.filter(Boolean).join(' ')

const initialsFromName = (name?: string) => {
  if (!name) return 'U'
  const [a, b] = name.trim().split(' ')
  return `${a?.[0] ?? 'U'}${b?.[0] ?? ''}`.toUpperCase()
}

export function PublicNavbar({
  logo = { url: '/', src: '/logo.png', alt: 'logo', title: 'AREA' },
  menu = [{ title: 'Explore', url: '/explore' }],
  auth = {
    login: { title: 'Login', url: '/login' },
    getStarted: { title: 'Get started', url: '/register' }
  },
  isAuthenticated = false,
  userName = 'Guest',
  userAvatarUrl,
  onLogin,
  onSignup,
  onLogout
}: LandingNavbarProps) {
  const [scrolled, setScrolled] = React.useState(false)
  const { data: currentUserData, error: currentUserError } =
    useCurrentUserQuery({ retry: false })
  const { mutate: logout } = useLogoutMutation()
  const router = useRouter()

  const handleLogout = React.useCallback(() => {
    logout(undefined, {
      onSuccess: () => {
        onLogout?.()
        router.push('/login')
      }
    })
  }, [logout, onLogout, router])

  React.useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 16)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  const isUnauthorized =
    currentUserError instanceof ApiError && currentUserError.status === 401
  const currentUser =
    !isUnauthorized && currentUserData?.user
      ? mapUserDTOToUser(currentUserData.user)
      : null
  const effectiveIsAuthenticated = currentUser ? true : isAuthenticated
  const effectiveUserName = currentUser?.email ?? userName
  const effectiveAvatarUrl = currentUser?.imageUrl ?? userAvatarUrl

  return (
    <div className="sticky top-0 z-50">
      <div
        className={cn(
          'mx-auto px-3 transition-[max-width] duration-700 ease-[cubic-bezier(.22,1,.36,1)] sm:px-4',
          scrolled ? 'max-w-6xl' : 'max-w-none'
        )}
      >
        <header
          className={cn(
            'supports-[backdrop-filter]:bg-background/50 backdrop-blur-xl',
            'transition-[border-radius,background-color,transform,box-shadow] duration-700 ease-[cubic-bezier(.22,1,.36,1)] will-change-transform',
            scrolled
              ? 'bg-background/70 ring-border/50 translate-y-2 rounded-2xl shadow-lg ring-1'
              : 'bg-background/0 translate-y-0 rounded-none shadow-none'
          )}
        >
          <section className={cn(scrolled ? 'py-2.5' : 'py-4')}>
            <div className="hidden items-center justify-between px-6 lg:flex">
              <div className="flex min-w-0 flex-1 items-center gap-6">
                <Link
                  href={logo.url}
                  className="group flex shrink-0 items-center gap-2"
                >
                  <Image
                    src={logo.src}
                    alt={logo.alt}
                    width={32}
                    height={32}
                    className="bg-accent/10 rounded-md object-contain p-1"
                  />
                  <span className="text-lg font-semibold tracking-tight">
                    {logo.title}
                  </span>
                </Link>

                <NavigationMenu>
                  <NavigationMenuList>
                    {menu.map((item) => renderMenuItem(item))}
                  </NavigationMenuList>
                </NavigationMenu>
              </div>

              <div className="flex shrink-0 items-center gap-2">
                <AnimatedThemeToggler />
                {!effectiveIsAuthenticated ? (
                  <>
                    <Button
                      asChild
                      variant="outline"
                      size="sm"
                      className="bg-accent/10 hover:bg-accent/20"
                      onClick={onLogin}
                    >
                      <Link
                        href={auth.login.url}
                        className="inline-flex items-center"
                      >
                        <LogIn className="mr-2 size-4" />
                        {auth.login.title}
                      </Link>
                    </Button>
                    <Button
                      asChild
                      size="sm"
                      className="bg-primary text-primary-foreground hover:bg-primary/90"
                      onClick={onSignup}
                    >
                      <Link
                        href={auth.getStarted.url}
                        className="inline-flex items-center"
                      >
                        <UserPlus className="mr-2 size-4" />
                        {auth.getStarted.title}
                      </Link>
                    </Button>
                  </>
                ) : (
                  <UserDropdown
                    userName={effectiveUserName}
                    userAvatarUrl={effectiveAvatarUrl}
                    onLogout={handleLogout}
                  />
                )}
              </div>
            </div>

            <div className="block lg:hidden">
              <div className="flex items-center justify-between px-4">
                <Link href={logo.url} className="flex items-center gap-2">
                  <Image
                    src={logo.src}
                    alt={logo.alt}
                    width={32}
                    height={32}
                    className="bg-accent/10 rounded-md object-contain p-1"
                  />
                  {!scrolled && (
                    <span className="text-base font-semibold">
                      {logo.title}
                    </span>
                  )}
                </Link>

                <Sheet>
                  <SheetTrigger asChild>
                    <Button variant="outline" size="icon">
                      <Menu className="size-4" />
                    </Button>
                  </SheetTrigger>

                  <SheetContent className="overflow-y-auto">
                    <SheetHeader>
                      <SheetTitle>
                        <Link
                          href={logo.url}
                          className="flex items-center gap-2"
                        >
                          <Image
                            src={logo.src}
                            alt={logo.alt}
                            width={32}
                            height={32}
                            className="bg-accent/10 rounded-md object-contain p-1"
                          />
                          <span className="text-base font-semibold">
                            {logo.title}
                          </span>
                        </Link>
                      </SheetTitle>
                    </SheetHeader>

                    <div className="mt-4 flex flex-col gap-6 p-1">
                      <Accordion
                        type="single"
                        collapsible
                        className="flex w-full flex-col gap-4"
                      >
                        {menu.map((item) => renderMobileMenuItem(item))}
                      </Accordion>

                      <div className="flex flex-col gap-3">
                        <AnimatedThemeToggler />
                        {!effectiveIsAuthenticated ? (
                          <>
                            <Button
                              asChild
                              variant="outline"
                              className="bg-accent/10 hover:bg-accent/20"
                              onClick={onLogin}
                            >
                              <Link
                                href={auth.login.url}
                                className="inline-flex items-center justify-center"
                              >
                                <LogIn className="mr-2 size-4" />
                                {auth.login.title}
                              </Link>
                            </Button>
                            <Button
                              asChild
                              className="bg-primary text-primary-foreground hover:bg-primary/90"
                              onClick={onSignup}
                            >
                              <Link
                                href={auth.getStarted.url}
                                className="inline-flex items-center justify-center"
                              >
                                <UserPlus className="mr-2 size-4" />
                                {auth.getStarted.title}
                              </Link>
                            </Button>
                          </>
                        ) : (
                          <MobileUserCard
                            userName={effectiveUserName}
                            userAvatarUrl={effectiveAvatarUrl}
                            onLogout={handleLogout}
                          />
                        )}
                      </div>
                    </div>
                  </SheetContent>
                </Sheet>
              </div>
            </div>
          </section>
        </header>
      </div>

      <style jsx global>{`
        @media (prefers-reduced-motion: reduce) {
          .transition-[max-width],
          .transition-[border-radius\\,background-color\\,transform\\,box-shadow] {
            transition: none !important;
          }
        }
      `}</style>
    </div>
  )
}

function UserDropdown({
  userName,
  userAvatarUrl,
  onLogout
}: {
  userName?: string
  userAvatarUrl?: string
  onLogout?: () => void
}) {
  const initials = initialsFromName(userName)

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          className="bg-accent/10 hover:bg-accent/20 gap-3"
        >
          <Avatar className="h-6 w-6">
            {userAvatarUrl ? (
              <AvatarImage src={userAvatarUrl} alt={userName ?? 'User'} />
            ) : (
              <AvatarFallback className="text-xs">{initials}</AvatarFallback>
            )}
          </Avatar>
          <span className="max-w-[140px] truncate text-sm">
            {userName ?? 'User'}
          </span>
          <ChevronRight className="h-3.5 w-3.5 transition-transform data-[state=open]:rotate-90" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="min-w-56">
        <DropdownMenuItem asChild>
          <Link href="/dashboard" className="w-full">
            <LayoutGrid className="mr-2 h-4 w-4" />
            Dashboard
          </Link>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={onLogout} className="text-destructive">
          <LogOut className="mr-2 h-4 w-4" />
          Logout
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

function MobileUserCard({
  userName,
  userAvatarUrl,
  onLogout
}: {
  userName?: string
  userAvatarUrl?: string
  onLogout?: () => void
}) {
  const initials = initialsFromName(userName)
  return (
    <div className="bg-accent/10 flex items-center justify-between rounded-lg p-3">
      <div className="flex items-center gap-3">
        <Avatar className="h-9 w-9">
          {userAvatarUrl ? (
            <AvatarImage src={userAvatarUrl} alt={userName ?? 'User'} />
          ) : (
            <AvatarFallback>{initials}</AvatarFallback>
          )}
        </Avatar>
        <div className="text-sm">
          <div className="font-medium">{userName ?? 'User'}</div>
          <div className="text-muted-foreground">Connecté</div>
        </div>
      </div>
      <Button
        variant="ghost"
        className="bg-accent/10 hover:bg-accent/20"
        onClick={onLogout}
      >
        <LogOut className="mr-2 size-4" />
        Logout
      </Button>
    </div>
  )
}

const renderMenuItem = (item: MenuItem) => {
  if (item.items) {
    return (
      <NavigationMenuItem key={item.title}>
        <NavigationMenuTrigger className="hover:bg-accent/10 data-[state=open]:bg-accent/20 gap-2 bg-transparent">
          <span className="inline-flex items-center gap-2">{item.title}</span>
        </NavigationMenuTrigger>
        <NavigationMenuContent className="bg-popover text-popover-foreground max-h-[80vh] min-w-[14rem] overflow-y-auto rounded-xl">
          <div className="grid w-[560px] grid-cols-2 gap-2 p-3 sm:w-[28rem]">
            <div className="bg-accent/10 hidden rounded-lg p-4 sm:block">
              <div className="mb-1 flex items-center gap-2 text-sm font-medium opacity-80">
                <LayoutGrid className="h-4 w-4" /> {item.title}
              </div>
              <p className="text-muted-foreground text-sm">
                Explore the different {item.title.toLowerCase()} sections.
              </p>
            </div>
            <ul className="grid gap-1">
              {item.items.map((sub) => (
                <li key={sub.title}>
                  <NavigationMenuLink asChild className="w-full">
                    <SubMenuLink item={sub} />
                  </NavigationMenuLink>
                </li>
              ))}
            </ul>
          </div>
        </NavigationMenuContent>
      </NavigationMenuItem>
    )
  }

  return (
    <NavigationMenuItem key={item.title}>
      <NavigationMenuLink
        href={item.url}
        className={cn(
          'group bg-background inline-flex h-10 w-max items-center justify-center rounded-md px-4 py-2 text-sm font-medium transition-colors',
          'hover:bg-muted hover:text-accent-foreground'
        )}
      >
        {item.title}
      </NavigationMenuLink>
    </NavigationMenuItem>
  )
}

const renderMobileMenuItem = (item: MenuItem) => {
  if (item.items) {
    return (
      <AccordionItem key={item.title} value={item.title} className="border-b-0">
        <AccordionTrigger className="text-md py-0 font-semibold hover:no-underline">
          {item.title}
        </AccordionTrigger>
        <AccordionContent className="mt-2">
          <div className="flex flex-col gap-1">
            {item.items.map((sub) => (
              <SubMenuLink key={sub.title} item={sub} />
            ))}
          </div>
        </AccordionContent>
      </AccordionItem>
    )
  }

  return (
    <Link key={item.title} href={item.url} className="text-md font-semibold">
      {item.title}
    </Link>
  )
}

const SubMenuLink = ({ item }: { item: MenuItem }) => (
  <Link
    href={item.url}
    className={cn(
      'group flex flex-row gap-3 rounded-md p-3 leading-none no-underline transition-all outline-none select-none',
      'hover:bg-accent/10 hover:text-accent-foreground'
    )}
  >
    <div className="text-foreground/90">
      {item.icon ?? <User className="size-5 shrink-0" />}
    </div>
    <div className="flex-1">
      <div className="text-sm font-semibold">{item.title}</div>
      {item.description && (
        <p className="text-muted-foreground text-sm leading-snug">
          {item.description}
        </p>
      )}
    </div>
    <ChevronRight className="mt-0.5 size-4 opacity-50 transition-transform group-hover:translate-x-0.5" />
  </Link>
)
