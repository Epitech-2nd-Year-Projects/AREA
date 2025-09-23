'use client'
import { useTranslations } from 'next-intl'
import { ServiceCard } from '@/components/service-card'
import { Service } from '@/lib/api/contracts/services'

// TODO: Replace with real supported services
const services: Service[] = [
  {
    name: 'github',
    displayName: 'GitHub',
    description: 'GitHub is a web-based Git repository hosting service.',
    actions: 42,
    reactions: 68
  },
  {
    name: 'discord',
    displayName: 'Discord',
    description:
      'Discord is a free, open-source, cross-platform instant messaging and voice-over-IP service.',
    actions: 28,
    reactions: 15
  },
  {
    name: 'onedrive',
    displayName: 'OneDrive',
    description:
      'OneDrive is a file hosting service offered by Microsoft that allows users to store, share, and collaborate on files from any device.',
    actions: 12,
    reactions: 60
  },
  {
    name: 'slack',
    displayName: 'Slack',
    description:
      'Slack is a cloud-based set of team collaboration tools and services that allows teams to communicate and collaborate more effectively.',
    actions: 9,
    reactions: 25
  },
  {
    name: 'riot',
    displayName: 'Riot',
    description: 'Riot Games is a leading global gaming company.',
    actions: 42,
    reactions: 68
  }
]

// TODO: Replaced with real linked services for the user
const userLinkedServices: string[] = ['github', 'discord']

export default function ExplorePage() {
  const t = useTranslations('ExplorePage')

  // TODO: Replace with auth state
  const isUserAuthenticated = false

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-12">
      <div className="flex flex-col gap-4">
        <h1 className="text-4xl font-bold tracking-tight">{t('title')}</h1>
        <p className="text-muted-foreground text-lg">{t('description')}</p>
      </div>
      <div className="grid items-stretch gap-6 sm:grid-cols-2 xl:grid-cols-4">
        {services.map((service) => {
          return (
            <ServiceCard
              key={service.name}
              service={service}
              authenticated={isUserAuthenticated}
              linked={userLinkedServices.includes(service.name)}
            />
          )
        })}
      </div>
    </div>
  )
}
