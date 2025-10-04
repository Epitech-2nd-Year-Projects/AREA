'use client'
import { useMemo } from 'react'
import { useTranslations } from 'next-intl'
import { Area } from '@/lib/api/contracts/areas'
import { buildMockAreaHistory, type MockAreaRun } from '@/lib/api/mock'
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
import { AlertTriangleIcon, CheckCircle2Icon, HistoryIcon } from 'lucide-react'

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
  const history = useMemo<MockAreaRun[]>(
    () => buildMockAreaHistory(area),
    [area]
  )

  const statusMeta: Record<
    MockAreaRun['status'],
    {
      label: string
      Icon: typeof CheckCircle2Icon
      badgeVariant: 'secondary' | 'destructive'
    }
  > = {
    success: {
      label: t('statusSuccess'),
      Icon: CheckCircle2Icon,
      badgeVariant: 'secondary'
    },
    failure: {
      label: t('statusFailure'),
      Icon: AlertTriangleIcon,
      badgeVariant: 'destructive'
    }
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

        {history.length === 0 ? (
          <div className="rounded-md border border-dashed bg-muted/40 p-8 text-center">
            <p className="text-sm text-muted-foreground">{t('empty')}</p>
          </div>
        ) : (
          <ScrollArea className="mt-2 max-h-[320px] pr-2">
            <div className="space-y-3">
              {history.map((run) => {
                const meta = statusMeta[run.status]
                const durationLabel = formatDuration(
                  run.durationMs,
                  ({ seconds }) => t('durationSeconds', { seconds })
                )

                return (
                  <div
                    key={run.id}
                    className="space-y-3 rounded-md border bg-card p-4 shadow-sm"
                  >
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <div>
                        <p className="text-sm font-medium">
                          {formatDateTime(run.executedAt)}
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

                    <p className="text-sm text-muted-foreground">
                      {run.status === 'success'
                        ? t('successSummary', {
                            count: run.reactionsTriggered,
                            duration: durationLabel
                          })
                        : t('failureSummary', {
                            duration: durationLabel,
                            error: run.errorMessage ?? t('unknownError')
                          })}
                    </p>

                    <Separator />

                    <div className="flex flex-wrap justify-between gap-2 text-xs text-muted-foreground">
                      <span>
                        {t('reactionsTriggered', {
                          count: run.reactionsTriggered
                        })}
                      </span>
                      <span>{t('duration', { duration: durationLabel })}</span>
                    </div>
                  </div>
                )
              })}
            </div>
          </ScrollArea>
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
