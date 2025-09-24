import { Service } from '@/lib/api/contracts/services'

export const mockServices: Service[] = [
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

export const mockUserLinkedServices: string[] = ['github', 'discord']
