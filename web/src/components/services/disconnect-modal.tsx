'use client'
import { useState } from 'react'
import { useTranslations } from 'next-intl'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger
} from '@/components/ui/dialog'

type DisconnectModalProps = {
  serviceName: string
  onConfirm: () => void | Promise<void>
  fullWidth?: boolean
}

export function DisconnectModal({
  serviceName,
  onConfirm,
  fullWidth = true
}: DisconnectModalProps) {
  const t = useTranslations('DisconnectModal')
  const [open, setOpen] = useState(false)

  const handleConfirm = async () => {
    await Promise.resolve(onConfirm())
    setOpen(false)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button
          className={`cursor-pointer ${fullWidth ? 'w-full' : ''}`}
          variant="destructive"
        >
          {t('trigger')}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('title')}</DialogTitle>
          <DialogDescription>
            {t('description', { service: serviceName })}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            className="cursor-pointer"
            variant="outline"
            onClick={() => setOpen(false)}
          >
            {t('cancel')}
          </Button>
          <Button
            className="cursor-pointer"
            variant="destructive"
            onClick={handleConfirm}
          >
            {t('confirm')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
