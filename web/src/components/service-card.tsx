'use client'
import { useTheme } from 'next-themes'
import { useRouter } from 'next/navigation'
import { cn } from '@/lib/utils'
import { Button } from './ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle
} from './ui/card'
import { MagicCard } from './ui/magic-card'
import { useTranslations } from 'next-intl'
import { Badge } from './ui/badge'

type ServiceCardProps = {
  service: {
    name: string
    description: string
    actions: number
    reactions: number
  }
  authenticated: boolean
  linked: boolean
}

export function ServiceCard({
  service,
  authenticated,
  linked
}: ServiceCardProps) {
  const t = useTranslations('ExplorePage')
  const { theme } = useTheme()
  const router = useRouter()
  const buttonState = linked
    ? { label: t('linked'), variant: 'secondary' as const, disabled: true }
    : authenticated
      ? { label: t('connect'), variant: 'default' as const, disabled: false }
      : { label: t('getStarted'), variant: 'outline' as const, disabled: false }
  const handleButtonClick = linked
    ? undefined
    : authenticated
      ? () => {
          // TODO: Redirect to back-end /oauth/:provider/start
        }
      : () => router.push('/register')

  return (
    <Card className="h-full w-full gap-0 border-none p-0 shadow-none">
      <MagicCard
        gradientColor={theme === 'dark' ? '#262626' : '#D9D9D955'}
        className="h-full"
        innerClassName="flex h-full w-full flex-col"
      >
        <CardHeader className="border-b border-border p-4 [.border-b]:pb-4">
          <CardTitle>{service.name}</CardTitle>
          <CardDescription>{service.description}</CardDescription>
        </CardHeader>
        <CardContent className="flex-1 p-4">
          <div className="flex flex-wrap gap-2">
            <Badge className="bg-muted text-muted-foreground inline-flex items-center rounded-full px-3 py-1 text-xs font-medium uppercase tracking-wide">
              {service.actions} {t('actions')}
            </Badge>
            <Badge className="bg-muted text-muted-foreground inline-flex items-center rounded-full px-3 py-1 text-xs font-medium uppercase tracking-wide">
              {service.reactions} {t('reactions')}
            </Badge>
          </div>
        </CardContent>
        <CardFooter className="mt-auto p-4">
          <Button
            className={cn('w-full', !linked && 'cursor-pointer')}
            variant={buttonState.variant}
            disabled={buttonState.disabled}
            onClick={handleButtonClick}
          >
            {buttonState.label}
          </Button>
        </CardFooter>
      </MagicCard>
    </Card>
  )
}
