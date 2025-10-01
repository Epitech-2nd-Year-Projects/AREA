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
  DialogTitle
} from '@/components/ui/dialog'

type DeleteAreaModalProps = {
  areaName: string
  open: boolean
  onOpenChange: (open: boolean) => void
  onConfirm?: () => void | Promise<void>
}

export function DeleteAreaModal({
  areaName,
  open,
  onOpenChange,
  onConfirm
}: DeleteAreaModalProps) {
  const t = useTranslations('DeleteAreaModal')
  const [isLoading, setIsLoading] = useState(false)

  const handleDialogOpenChange = (nextOpen: boolean) => {
    if (!nextOpen) {
      setIsLoading(false)
    }

    onOpenChange(nextOpen)
  }

  const handleConfirm = async () => {
    if (!onConfirm) {
      onOpenChange(false)
      return
    }

    setIsLoading(true)
    await Promise.resolve(onConfirm())
    setIsLoading(false)
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={handleDialogOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('title')}</DialogTitle>
          <DialogDescription>
            {t('description', { area: areaName })}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            className="cursor-pointer"
            onClick={() => onOpenChange(false)}
            disabled={isLoading}
          >
            {t('cancel')}
          </Button>
          <Button
            type="button"
            variant="destructive"
            className="cursor-pointer"
            onClick={handleConfirm}
            disabled={isLoading}
          >
            {t('confirm')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
