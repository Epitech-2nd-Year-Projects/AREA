'use client'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger
} from '@/components/ui/dropdown-menu'
import { User } from '@/lib/api/contracts/users'
import { ColumnDef } from '@tanstack/react-table'
import { MoreHorizontal } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { useState } from 'react'
import { EditUserDialog } from './edit-user-dialog'

type ColumnKey = 'id' | 'email' | 'role' | 'actions'

function ColumnHeader({ translationKey }: { translationKey: ColumnKey }) {
  const t = useTranslations('AdminUsersPage.table.columns')

  return <span>{t(translationKey)}</span>
}

function ActionsCell({ user }: { user: User }) {
  const t = useTranslations('AdminUsersPage.table.actions')
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false)

  return (
    <>
      <EditUserDialog
        user={user}
        isOpen={isEditDialogOpen}
        onOpenChange={setIsEditDialogOpen}
      />
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="h-8 w-8 p-0">
            <span className="sr-only">{t('openMenu')}</span>
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>{t('label')}</DropdownMenuLabel>
          <DropdownMenuItem
            onClick={() => navigator.clipboard.writeText(user.id)}
          >
            {t('copyId')}
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => setIsEditDialogOpen(true)}>
            {t('editUser')}
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </>
  )
}

export const columns: ColumnDef<User>[] = [
  {
    accessorKey: 'id',
    header: () => <ColumnHeader translationKey="id" />
  },
  {
    accessorKey: 'email',
    header: () => <ColumnHeader translationKey="email" />
  },
  {
    accessorKey: 'role',
    header: () => <ColumnHeader translationKey="role" />
  },
  {
    id: 'actions',
    header: () => <ColumnHeader translationKey="actions" />,
    cell: ({ row }) => <ActionsCell user={row.original} />
  }
]
