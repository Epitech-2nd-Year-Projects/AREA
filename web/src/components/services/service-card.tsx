'use client'
import { useTheme } from 'next-themes'
import { useRouter } from 'next/navigation'
import { cn } from '@/lib/utils'
import { useTranslations } from 'next-intl'
import { Play, Repeat } from 'lucide-react'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle
} from '@/components/ui/card'
import { MagicCard } from '@/components/ui/magic-card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger
} from '@/components/ui/accordion'
import { ScrollArea } from '@/components/ui/scroll-area'
import type { Service } from '@/lib/api/contracts/services'

type ServiceCardProps = {
  service: Service
  authenticated: boolean
  linked: boolean
  isMinimal?: boolean
}

export function ServiceCard({
  service,
  authenticated,
  linked,
  isMinimal = false
}: ServiceCardProps) {
  const t = useTranslations('ServiceCard')
  const { theme } = useTheme()
  const router = useRouter()
  const gradientColor = theme === 'dark' ? '#262626' : '#D9D9D955'

  if (isMinimal) {
    return (
      <Card className="h-full w-full gap-0 overflow-hidden border-none p-0 shadow-none">
        <MagicCard
          gradientColor={gradientColor}
          className="h-full"
          innerClassName="flex h-full w-full flex-col overflow-hidden"
        >
          <CardHeader className="border-border p-4 [.border-b]:pb-4">
            <CardTitle>{service.displayName}</CardTitle>
            <CardDescription>{service.description}</CardDescription>
          </CardHeader>
        </MagicCard>
      </Card>
    )
  }

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
    <Card className="h-full w-full gap-0 overflow-hidden border-none p-0 shadow-none">
      <MagicCard
        gradientColor={gradientColor}
        className="h-full"
        innerClassName="flex h-full w-full flex-col overflow-hidden"
      >
        <CardHeader className="border-b border-border p-4 [.border-b]:pb-4">
          <CardTitle>{service.displayName}</CardTitle>
          <CardDescription>{service.description}</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-1 flex-col gap-4 p-4">
          <div className="flex flex-wrap gap-2">
            <Badge variant="secondary" className="uppercase">
              {service.actions.length} {t('actions')}
            </Badge>
            <Badge variant="secondary" className="uppercase">
              {service.reactions.length} {t('reactions')}
            </Badge>
          </div>

          <Accordion type="single" collapsible className="w-full">
            <AccordionItem value="details">
              <AccordionTrigger className="text-left text-sm font-semibold uppercase tracking-wide">
                {t('viewCapabilities')}
              </AccordionTrigger>
              <AccordionContent>
                <ScrollArea className="h-[14rem] w-full overflow-hidden rounded-lg border bg-background/40 sm:h-[16rem]">
                  <div className="flex flex-col gap-3 p-4 pr-6">
                    <div className="grid gap-4 sm:grid-cols-2">
                      <div className="flex flex-col gap-3 rounded-lg border bg-background/60 p-4 shadow-sm">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide">
                            <Play className="h-4 w-4" aria-hidden />
                            {t('actions')}
                          </div>
                          <Badge variant="outline">
                            {service.actions.length}
                          </Badge>
                        </div>
                        <ul className="space-y-3 text-left">
                          {service.actions.map((action) => (
                            <li
                              key={action.id}
                              className="rounded-md border border-dashed bg-background/80 p-3"
                            >
                              <p className="text-sm font-medium">
                                {action.name}
                              </p>
                              <p className="text-muted-foreground text-xs leading-snug">
                                {action.description}
                              </p>
                            </li>
                          ))}
                        </ul>
                      </div>
                      <div className="flex flex-col gap-3 rounded-lg border bg-background/60 p-4 shadow-sm">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide">
                            <Repeat className="h-4 w-4" aria-hidden />
                            {t('reactions')}
                          </div>
                          <Badge variant="outline">
                            {service.reactions.length}
                          </Badge>
                        </div>
                        <ul className="space-y-3 text-left">
                          {service.reactions.map((reaction) => (
                            <li
                              key={reaction.id}
                              className="rounded-md border border-dashed bg-background/80 p-3"
                            >
                              <p className="text-sm font-medium">
                                {reaction.name}
                              </p>
                              <p className="text-muted-foreground text-xs leading-snug">
                                {reaction.description}
                              </p>
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </div>
                </ScrollArea>
              </AccordionContent>
            </AccordionItem>
          </Accordion>
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
