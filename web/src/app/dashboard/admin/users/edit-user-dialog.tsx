'use client'

import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from '@/components/ui/select'
import { useTranslations } from 'next-intl'
import type { User } from '@/lib/api/contracts/users'
import {
  useAdminResetUserPasswordMutation,
  useAdminUpdateUserEmailMutation,
  useAdminUpdateUserStatusMutation
} from '@/lib/api/openapi/users'

type EditUserDialogProps = {
  user: User
  isOpen: boolean
  onOpenChange: (isOpen: boolean) => void
}

export function EditUserDialog({
  user,
  isOpen,
  onOpenChange
}: EditUserDialogProps) {
  const t = useTranslations('AdminUsersPage.editDialog')
  const [email, setEmail] = useState(user.email)
  const [newPassword, setNewPassword] = useState('')
  const [status, setStatus] = useState(user.status)

  const { mutate: updateEmail } = useAdminUpdateUserEmailMutation()
  const { mutate: resetPassword } = useAdminResetUserPasswordMutation()
  const { mutate: updateStatus } = useAdminUpdateUserStatusMutation()

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault()

    if (email !== user.email) {
      updateEmail({ userId: user.id, body: { email } })
    }
    if (newPassword) {
      resetPassword({ userId: user.id, body: { newPassword } })
    }
    if (status !== user.status) {
      updateStatus({ userId: user.id, body: { status } })
    }

    onOpenChange(false)
  }

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{t('title')}</DialogTitle>
          <DialogDescription>
            {t('description')}
            {!user.hasPassword && (
              <p className="text-sm text-muted-foreground mt-2">
                {t('oauthUserDescription')}
              </p>
            )}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit}>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="email">{t('email')}</Label>
              <Input
                id="email"
                value={email}
                disabled={!user.hasPassword}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password">{t('newPassword')}</Label>
              <Input
                id="password"
                type="password"
                disabled={!user.hasPassword}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="status">{t('status')}</Label>
              <Select value={status} onValueChange={setStatus}>
                <SelectTrigger>
                  <SelectValue placeholder={t('statusPlaceholder')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="active">{t('statuses.active')}</SelectItem>
                  <SelectItem value="pending">
                    {t('statuses.pending')}
                  </SelectItem>
                  <SelectItem value="suspended">
                    {t('statuses.suspended')}
                  </SelectItem>
                  <SelectItem value="deleted">
                    {t('statuses.deleted')}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button type="submit">{t('save')}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
