'use client'

import { Moon, SunDim } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { flushSync } from 'react-dom'
import { cn } from '@/lib/utils'
import { useTheme } from 'next-themes'

type props = {
  className?: string
}

export const AnimatedThemeToggler = ({ className }: props) => {
  const { resolvedTheme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)
  const [isDarkMode, setIsDarkMode] = useState(false)
  const buttonRef = useRef<HTMLButtonElement | null>(null)

  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    if (!mounted) return
    setIsDarkMode(resolvedTheme === 'dark')
  }, [mounted, resolvedTheme])
  const changeTheme = async () => {
    if (!buttonRef.current) return
    const next = isDarkMode ? 'light' : 'dark'

    const run = () => {
      flushSync(() => {
        setTheme(next)
        setIsDarkMode(next === 'dark')
      })
    }

    const vt = document.startViewTransition?.(run)
    if (!vt) {
      run()
      return
    }

    await vt.ready

    const { top, left, width, height } =
      buttonRef.current.getBoundingClientRect()
    const y = top + height / 2
    const x = left + width / 2

    const right = window.innerWidth - left
    const bottom = window.innerHeight - top
    const maxRad = Math.hypot(Math.max(left, right), Math.max(top, bottom))

    document.documentElement.animate(
      {
        clipPath: [
          `circle(0px at ${x}px ${y}px)`,
          `circle(${maxRad}px at ${x}px ${y}px)`
        ]
      },
      {
        duration: 700,
        easing: 'ease-in-out',
        pseudoElement: '::view-transition-new(root)'
      }
    )
  }

  if (!mounted) return null

  return (
    <button ref={buttonRef} onClick={changeTheme} className={cn(className)}>
      {isDarkMode ? <SunDim /> : <Moon />}
    </button>
  )
}
