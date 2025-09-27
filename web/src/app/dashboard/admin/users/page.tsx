import { User } from '@/lib/api/contracts/users'
import { columns } from './columns'
import { DataTable } from './data-table'
import { mockUsers } from '@/data/mocks'
import { getTranslations } from 'next-intl/server'

async function getData(): Promise<User[]> {
  return mockUsers
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
