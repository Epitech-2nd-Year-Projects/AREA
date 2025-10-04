import { User } from '@/lib/api/contracts/users'
import { columns } from './columns'
import { DataTable } from './data-table'
import { getTranslations } from 'next-intl/server'
import { mapUserDTOToUser } from '@/lib/api/openapi/auth'
import { currentUserServer } from '@/lib/api/openapi/auth/server'
import { ApiError } from '@/lib/api/http/errors'

async function getData(): Promise<User[]> {
  try {
    const response = await currentUserServer()
    return [mapUserDTOToUser(response.user)]
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) {
      return []
    }
    throw error
  }
}

export default async function AdminUsersPage() {
  const t = await getTranslations('AdminUsersPage')
  const data = await getData()

  return (
    <div className="container mx-auto py-10">
      <h1 className="text-3xl font-bold tracking-tight">{t('title')}</h1>
      <div className="mt-6">
        <DataTable columns={columns} data={data} />
      </div>
    </div>
  )
}
