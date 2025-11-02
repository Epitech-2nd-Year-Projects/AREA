'use client'
import { useEffect } from 'react'
import { useTranslations } from 'next-intl'
import { toast } from 'sonner'
import { Area } from '@/lib/api/contracts/areas'
import { useDeleteAreaMutation } from '@/lib/api/openapi/areas'
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
  area: Area
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function DeleteAreaModal({
  area,
  open,
  onOpenChange
}: DeleteAreaModalProps) {
  const t = useTranslations('DeleteAreaModal')
  const deleteMutation = useDeleteAreaMutation(area.id, {
    onSuccess: () => {
      toast.success(t('success', { area: area.name }))
      onOpenChange(false)
    },
    onError: (error) => {
      toast.error(error.message || t('error'))
    }
  })
  const { mutate, isPending, reset } = deleteMutation

  useEffect(() => {
    if (!open) {
      reset()
    }
  }, [open, reset])

  const handleDialogOpenChange = (nextOpen: boolean) => {
    onOpenChange(nextOpen)
  }

  const handleConfirm = async () => {
    if (isPending) return
    mutate(undefined)
  }

  const isLoading = isPending

  return (
    <Dialog open={open} onOpenChange={handleDialogOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('title')}</DialogTitle>
          <DialogDescription>
            {t('description', { area: area.name })}
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
