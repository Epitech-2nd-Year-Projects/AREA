'use client'

import { Check, Languages } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useLocale } from 'next-intl'
import { useRouter } from 'next/navigation'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'
import { cn } from '@/lib/utils'

const COOKIE_MAX_AGE = 60 * 60 * 24 * 365 // 1 year

const SUPPORTED_LOCALES = [
  { code: 'en', label: 'English' },
  { code: 'fr', label: 'Français' }
] as const

type LanguageSwitcherProps = {
  className?: string
}

export function LanguageSwitcher({ className }: LanguageSwitcherProps) {
  const locale = useLocale()
  const router = useRouter()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  const activeLocale = useMemo(() => {
    const found = SUPPORTED_LOCALES.find((item) => item.code === locale)
    return found ?? SUPPORTED_LOCALES[0]
  }, [locale])

  if (!mounted || SUPPORTED_LOCALES.length < 2) return null

  const handleLocaleChange = (
    code: (typeof SUPPORTED_LOCALES)[number]['code']
  ) => {
    document.cookie = `locale=${code}; path=/; max-age=${COOKIE_MAX_AGE}; SameSite=Lax`
    router.refresh()
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={cn(
            'flex items-center gap-2 border border-border/40 bg-transparent px-2 py-1 text-sm hover:border-border',
            className
          )}
          aria-label="Open language menu"
        >
          <Languages className="h-4 w-4" />
          <span>{activeLocale.code.toUpperCase()}</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="min-w-40" align="end">
        {SUPPORTED_LOCALES.map((item) => {
          const isActive = item.code === activeLocale.code

          return (
            <DropdownMenuItem
              key={item.code}
              onSelect={(event) => {
                if (isActive) {
                  event.preventDefault()
                  return
                }
                handleLocaleChange(item.code)
              }}
              className="flex items-center gap-2"
            >
              <span className="flex-1 text-sm">{item.label}</span>
              {isActive ? <Check className="h-4 w-4" /> : null}
            </DropdownMenuItem>
          )
        })}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
