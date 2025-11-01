'use client'
import { useEffect } from 'react'
import { Loader2, Play, Repeat } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { toast } from 'sonner'
import { useAboutQuery, mapAboutResponse } from '@/lib/api/openapi/about'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from '@/components/ui/card'
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger
} from '@/components/ui/accordion'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Badge } from '@/components/ui/badge'

export default function AboutPage() {
  const t = useTranslations('AboutPage')
  const { data, isLoading, isError } = useAboutQuery()

  useEffect(() => {
    if (isError) {
      toast.error(t('error'))
    }
  }, [isError, t])

  if (isLoading) {
    return (
      <div className="mx-auto flex max-w-5xl items-center justify-center py-24">
        <Loader2 className="mr-2 h-6 w-6 animate-spin" aria-hidden />
        <span className="text-muted-foreground text-sm">{t('loading')}</span>
      </div>
    )
  }

  if (isError || !data) {
    return null
  }

  const about = mapAboutResponse(data)

  const formattedServerTime = new Intl.DateTimeFormat('en-US', {
    dateStyle: 'full',
    timeStyle: 'long'
  }).format(new Date(about.server.currentTime))

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8">
      <header className="flex flex-col gap-2">
        <h1 className="text-4xl font-bold tracking-tight">{t('title')}</h1>
        <p className="text-muted-foreground text-lg">{t('description')}</p>
      </header>

      <div className="grid items-start gap-6 lg:grid-cols-2">
        <Card className="self-start">
          <CardHeader>
            <CardTitle>{t('clientSectionTitle')}</CardTitle>
            <CardDescription>{t('clientSectionDescription')}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <dl className="space-y-4">
              <div className="flex flex-col gap-1">
                <dt className="text-muted-foreground text-xs font-semibold uppercase tracking-wide">
                  {t('hostLabel')}
                </dt>
                <dd className="font-medium break-all lg:break-words">
                  {about.client.host}
                </dd>
              </div>
            </dl>
          </CardContent>
        </Card>

        <Card className="self-start">
          <CardHeader>
            <CardTitle>{t('serverSectionTitle')}</CardTitle>
            <CardDescription>{t('serverSectionDescription')}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <dl className="space-y-4">
              <div className="flex flex-col gap-1">
                <dt className="text-muted-foreground text-xs font-semibold uppercase tracking-wide">
                  {t('currentTimeLabel')}
                </dt>
                <dd className="font-medium">{formattedServerTime}</dd>
              </div>
            </dl>

            <section className="flex flex-col gap-4">
              <h2 className="text-muted-foreground text-xs font-semibold uppercase tracking-wide">
                {t('servicesLabel')}
              </h2>
              <ScrollArea className="h-[22rem] w-full overflow-hidden rounded-lg border bg-background/40 sm:h-[28rem]">
                <div className="flex flex-col gap-3 p-4 pr-6">
                  <Accordion
                    type="single"
                    collapsible
                    className="w-full"
                    defaultValue={about.server.services[0]?.name}
                  >
                    {about.server.services.map((service) => (
                      <AccordionItem key={service.name} value={service.name}>
                        <AccordionTrigger className="flex flex-col gap-3 text-left sm:flex-row sm:items-center sm:justify-between sm:gap-6">
                          <div className="space-y-1">
                            <p className="text-base font-semibold leading-none">
                              {service.displayName}
                            </p>
                            {service.description ? (
                              <p className="text-muted-foreground text-sm leading-relaxed">
                                {service.description}
                              </p>
                            ) : null}
                          </div>
                          <div className="flex items-center gap-2">
                            <Badge variant="secondary">
                              {service.actions.length} {t('actionsLabel')}
                            </Badge>
                            <Badge variant="secondary">
                              {service.reactions.length} {t('reactionsLabel')}
                            </Badge>
                          </div>
                        </AccordionTrigger>
                        <AccordionContent className="space-y-4 text-sm leading-relaxed">
                          <div className="grid gap-4 sm:grid-cols-2">
                            <div className="flex flex-col gap-3 rounded-lg border bg-background/60 p-4 shadow-sm">
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide">
                                  <Play className="h-4 w-4" aria-hidden />
                                  {t('actionsLabel')}
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
                                  {t('reactionsLabel')}
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
                        </AccordionContent>
                      </AccordionItem>
                    ))}
                  </Accordion>
                </div>
              </ScrollArea>
            </section>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
