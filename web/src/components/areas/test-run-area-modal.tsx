'use client'
import { useMemo, useState } from 'react'
import { useTranslations } from 'next-intl'
import { toast } from 'sonner'
import { Area } from '@/lib/api/contracts/areas'
import { useExecuteAreaMutation } from '@/lib/api/openapi/areas'
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
import { Separator } from '@/components/ui/separator'

function formatDateTime(date: Date) {
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

type TestRunAreaModalProps = {
  area: Area
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function TestRunAreaModal({
  area,
  open,
  onOpenChange
}: TestRunAreaModalProps) {
  const t = useTranslations('TestRunAreaModal')
  const [lastRunAt, setLastRunAt] = useState<Date | null>(null)
  const executeMutation = useExecuteAreaMutation(area.id, {
    onSuccess: () => {
      setLastRunAt(new Date())
      toast.success(t('success', { area: area.name }))
    },
    onError: (error) => {
      toast.error(error.message || t('error'))
    }
  })

  const summaryState = useMemo(() => {
    if (executeMutation.isPending) {
      return 'running' as const
    }
    if (!lastRunAt) {
      return 'idle' as const
    }

    return 'completed' as const
  }, [executeMutation.isPending, lastRunAt])

  const handleDialogOpenChange = (nextOpen: boolean) => {
    if (!nextOpen) {
      setLastRunAt(null)
      executeMutation.reset()
    }

    onOpenChange(nextOpen)
  }

  const handleSimulateRun = () => {
    if (executeMutation.isPending) {
      return
    }
    executeMutation.mutate(undefined)
  }

  return (
    <Dialog open={open} onOpenChange={handleDialogOpenChange}>
      <DialogContent className="sm:max-w-[520px]">
        <DialogHeader>
          <DialogTitle>{t('title')}</DialogTitle>
          <DialogDescription>
            {t('description', { area: area.name })}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          <div className="rounded-md border bg-muted/40 p-4">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium">{t('summaryTitle')}</p>
              <Badge
                variant={
                  summaryState === 'completed'
                    ? 'default'
                    : summaryState === 'running'
                      ? 'default'
                      : 'secondary'
                }
              >
                {summaryState === 'running'
                  ? t('statusRunning')
                  : summaryState === 'completed'
                    ? t('statusCompleted')
                    : t('statusIdle')}
              </Badge>
            </div>
            <p className="mt-2 text-sm text-muted-foreground">
              {summaryState === 'completed'
                ? t('runAt', { date: formatDateTime(lastRunAt!) })
                : summaryState === 'running'
                  ? t('runningDescription')
                  : t('idleDescription')}
            </p>
          </div>

          <div className="space-y-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                {t('actionHeading')}
              </p>
              <div className="mt-2 rounded-md border p-3">
                <p className="text-sm font-medium">{area.action.name}</p>
                <p className="text-xs text-muted-foreground">
                  {area.action.description}
                </p>
              </div>
            </div>

            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                {t('reactionsHeading')}
              </p>
              <div className="mt-2 space-y-3 rounded-md border p-3">
                {area.reactions.length === 0 ? (
                  <p className="text-xs text-muted-foreground">
                    {t('noReactions')}
                  </p>
                ) : (
                  area.reactions.map((reaction, index) => (
                    <div key={reaction.id}>
                      <p className="text-sm font-medium">{reaction.name}</p>
                      <p className="text-xs text-muted-foreground">
                        {reaction.description}
                      </p>
                      {index < area.reactions.length - 1 ? (
                        <Separator className="my-2" />
                      ) : null}
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
          >
            {t('close')}
          </Button>
          <Button
            type="button"
            onClick={handleSimulateRun}
            disabled={executeMutation.isPending}
          >
            {summaryState === 'completed' ? t('runAgain') : t('runTest')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
