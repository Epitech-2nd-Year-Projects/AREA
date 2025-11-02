'use client'
import { useTranslations } from 'next-intl'
import {
  AlertTriangleIcon,
  CheckCircle2Icon,
  HistoryIcon,
  Loader2
} from 'lucide-react'
import { Area, AreaHistoryEntry } from '@/lib/api/contracts/areas'
import { useAreaHistoryQuery } from '@/lib/api/openapi/areas'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle
} from '@/components/ui/dialog'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'

const MILLISECONDS_IN_SECOND = 1000

function formatDateTime(date: Date) {
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

function formatDuration(
  durationMs: number,
  formatter: (values: { seconds: number }) => string
) {
  const seconds = Math.max(1, Math.round(durationMs / MILLISECONDS_IN_SECOND))

  return formatter({ seconds })
}

type AreaHistoryModalProps = {
  area: Area
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function AreaHistoryModal({
  area,
  open,
  onOpenChange
}: AreaHistoryModalProps) {
  const t = useTranslations('AreaHistoryModal')
  const historyQuery = useAreaHistoryQuery(area.id, {
    enabled: open
  })
  const history = historyQuery.data ?? []

  const getStatusMeta = (
    entry: AreaHistoryEntry
  ): {
    label: string
    Icon: typeof CheckCircle2Icon
    badgeVariant: 'secondary' | 'destructive'
  } => {
    const status = entry.status.toLowerCase()
    if (status === 'succeeded' || status === 'success') {
      return {
        label: t('statusSuccess'),
        Icon: CheckCircle2Icon,
        badgeVariant: 'secondary'
      }
    }
    if (status === 'failed' || status === 'failure') {
      return {
        label: t('statusFailure'),
        Icon: AlertTriangleIcon,
        badgeVariant: 'destructive'
      }
    }
    return {
      label: t('statusGeneric', { status: entry.status }),
      Icon: HistoryIcon,
      badgeVariant: 'secondary'
    }
  }

  const renderHistoryList = (entries: AreaHistoryEntry[]) => {
    if (entries.length === 0) {
      return (
        <div className="rounded-md border border-dashed bg-muted/40 p-8 text-center">
          <p className="text-sm text-muted-foreground">{t('empty')}</p>
        </div>
      )
    }

    return (
      <ScrollArea className="mt-2 max-h-[320px] pr-2">
        <div className="space-y-3">
          {entries.map((entry) => {
            const meta = getStatusMeta(entry)
            const durationMs = (() => {
              const raw = entry.resultPayload?.durationMs
              return typeof raw === 'number' ? raw : null
            })()
            const reactionsTriggered = (() => {
              const raw = entry.resultPayload?.reactionsTriggered
              return typeof raw === 'number' ? raw : 0
            })()
            const durationLabel = durationMs
              ? formatDuration(durationMs, ({ seconds }) =>
                  t('durationSeconds', { seconds })
                )
              : t('durationUnavailable')

            const summaryText =
              meta.badgeVariant === 'destructive'
                ? t('failureSummary', {
                    duration: durationLabel,
                    error: entry.error ?? t('unknownError')
                  })
                : t('successSummary', {
                    count: reactionsTriggered,
                    duration: durationLabel
                  })

            return (
              <div
                key={entry.jobId}
                className="space-y-3 rounded-md border bg-card p-4 shadow-sm"
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div>
                    <p className="text-sm font-medium">
                      {formatDateTime(entry.runAt)}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {t('triggeredBy', { action: area.action.name })}
                    </p>
                  </div>
                  <Badge variant={meta.badgeVariant}>
                    <meta.Icon className="size-3" />
                    {meta.label}
                  </Badge>
                </div>

                <p className="text-sm text-muted-foreground">{summaryText}</p>

                <Separator />

                <div className="flex flex-wrap justify-between gap-2 text-xs text-muted-foreground">
                  <span>
                    {t('reactionsTriggered', {
                      count: reactionsTriggered
                    })}
                  </span>
                  <span>{t('duration', { duration: durationLabel })}</span>
                </div>
              </div>
            )
          })}
        </div>
      </ScrollArea>
    )
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[560px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <HistoryIcon className="size-4" />
            {t('title')}
          </DialogTitle>
          <DialogDescription>
            {t('description', { area: area.name })}
          </DialogDescription>
        </DialogHeader>

        {historyQuery.isLoading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="size-5 animate-spin text-muted-foreground" />
            <span className="ml-2 text-sm text-muted-foreground">
              {t('loading')}
            </span>
          </div>
        ) : historyQuery.isError ? (
          <div className="flex flex-col items-center justify-center gap-4 rounded-md border border-dashed bg-muted/40 p-8 text-center">
            <p className="text-sm text-muted-foreground">{t('error')}</p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => historyQuery.refetch()}
            >
              {t('retry')}
            </Button>
          </div>
        ) : (
          renderHistoryList(history)
        )}

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
          >
            {t('close')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
