'use client'
import { useEffect, useState } from 'react'
import { useTheme } from 'next-themes'
import { useTranslations } from 'next-intl'
import { Area } from '@/lib/api/contracts/areas'
import { PenIcon, PowerIcon, TrashIcon } from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from '../ui/card'
import { MagicCard } from '../ui/magic-card'
import { Button } from '../ui/button'
import { Tooltip, TooltipContent, TooltipTrigger } from '../ui/tooltip'

type AreaCardProps = {
  area: Area
}

export function AreaCard({ area }: AreaCardProps) {
  const t = useTranslations('AreaCard')
  const { theme } = useTheme()
  const [isEnabled, setIsEnabled] = useState(area.enabled)

  useEffect(() => {
    setIsEnabled(area.enabled)
  }, [area.enabled])

  const toggleLabel = isEnabled ? t('disableArea') : t('enableArea')

  return (
    <Card
      className="h-full w-full gap-0 border-none p-0 shadow-none"
      aria-disabled={!isEnabled}
    >
      <MagicCard
        gradientColor={theme === 'dark' ? '#262626' : '#D9D9D955'}
        className={cn(
          'h-full transition-[opacity,filter] duration-200',
          !isEnabled && 'opacity-60 saturate-[0.85]'
        )}
        innerClassName="flex h-full w-full flex-col"
      >
        <CardHeader className="border-b border-border p-4 [.border-b]:pb-4">
          <CardTitle>{area.name}</CardTitle>
          <CardAction className="flex items-center gap-2">
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant={isEnabled ? 'secondary' : 'outline'}
                  size="icon"
                  className="size-8 cursor-pointer"
                  aria-label={toggleLabel}
                  onClick={() => setIsEnabled((prev) => !prev)}
                >
                  <PowerIcon
                    className={cn(
                      'size-4',
                      !isEnabled && 'text-muted-foreground'
                    )}
                  />
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>{toggleLabel}</p>
              </TooltipContent>
            </Tooltip>
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="secondary"
                  size="icon"
                  className="size-8 cursor-pointer"
                >
                  <PenIcon />
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>{t('editArea')}</p>
              </TooltipContent>
            </Tooltip>
            <Tooltip>
              <TooltipTrigger asChild>
                <Button
                  variant="secondary"
                  size="icon"
                  className="size-8 cursor-pointer"
                >
                  <TrashIcon />
                </Button>
              </TooltipTrigger>
              <TooltipContent>
                <p>{t('deleteArea')}</p>
              </TooltipContent>
            </Tooltip>
          </CardAction>
        </CardHeader>
        <CardContent className="flex-1 p-4">
          <CardDescription>{area.description}</CardDescription>
        </CardContent>
      </MagicCard>
    </Card>
  )
}
