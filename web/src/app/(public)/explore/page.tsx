import { useTranslations } from 'next-intl'
import { ServiceCard } from '@/components/service-card'

type Service = {
  name: string
  description: string
  actions: number
  reactions: number
}

const services: Service[] = [
  {
    name: 'GitHub',
    description: 'GitHub is a web-based Git repository hosting service.',
    actions: 42,
    reactions: 68
  },
  {
    name: 'Discord',
    description:
      'Discord is a free, open-source, cross-platform instant messaging and voice-over-IP service.',
    actions: 28,
    reactions: 15
  },
  {
    name: 'OneDrive',
    description:
      'OneDrive is a file hosting service offered by Microsoft that allows users to store, share, and collaborate on files from any device.',
    actions: 12,
    reactions: 60
  },
  {
    name: 'Slack',
    description:
      'Slack is a cloud-based set of team collaboration tools and services that allows teams to communicate and collaborate more effectively.',
    actions: 9,
    reactions: 25
  },
  {
    name: 'Riot Games',
    description: 'Riot Games is a leading global gaming company.',
    actions: 42,
    reactions: 68
  }
]

export default function ExplorePage() {
  const t = useTranslations('ExplorePage')
  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-12">
      <div className="flex flex-col gap-4">
        <h1 className="text-4xl font-bold tracking-tight">{t('title')}</h1>
        <p className="text-muted-foreground text-lg">{t('description')}</p>
      </div>
      <div className="grid items-stretch gap-6 sm:grid-cols-2 xl:grid-cols-4">
        {services.map((service) => {
          return <ServiceCard key={service.name} service={service} />
        })}
      </div>
    </div>
  )
}
