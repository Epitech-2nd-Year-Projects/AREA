import { Action } from '@/lib/api/contracts/actions'
import { Area } from '@/lib/api/contracts/areas'
import { Reaction } from '@/lib/api/contracts/reactions'
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

export const mockActions: Action[] = [
  {
    id: '1',
    name: 'An issue is opened',
    description: 'An issue is opened in a repository',
    service_name: 'github'
  },
  {
    id: '2',
    name: 'A message is sent',
    description: 'A message is sent in a channel',
    service_name: 'discord'
  },
  {
    id: '3',
    name: 'A file is uploaded',
    description: 'A file is uploaded',
    service_name: 'onedrive'
  },
  {
    id: '4',
    name: 'A message is posted',
    description: 'A message is posted in a channel',
    service_name: 'slack'
  },
  {
    id: '5',
    name: 'A game is played',
    description: 'A game is played',
    service_name: 'riot'
  }
]

export const mockReactions: Reaction[] = [
  {
    id: '1',
    name: 'Assign a label',
    description: 'Assign a label to an issue',
    service_name: 'github'
  },
  {
    id: '2',
    name: 'Send a message',
    description: 'Send a message in a channel',
    service_name: 'discord'
  },
  {
    id: '3',
    name: 'Upload a file',
    description: 'Upload a file',
    service_name: 'onedrive'
  },
  {
    id: '4',
    name: 'Post a message',
    description: 'Post a message in a channel',
    service_name: 'slack'
  },
  {
    id: '5',
    name: 'Play a game',
    description: 'Play a game',
    service_name: 'riot'
  }
]

export const mockUserLinkedAreas: Area[] = [
  {
    id: '1',
    name: 'Issue to Discord',
    description:
      'When an issue is opened in a repository, send a message in a channel',
    action: mockActions[0],
    reactions: [mockReactions[1]]
  },
  {
    id: '2',
    name: 'Message to Discord',
    description:
      'When a message is sent in a channel, send a message in a channel',
    action: mockActions[1],
    reactions: [mockReactions[1]]
  },
  {
    id: '3',
    name: 'File to Discord',
    description: 'When a file is uploaded, send a message in a channel',
    action: mockActions[2],
    reactions: [mockReactions[1]]
  },
  {
    id: '4',
    name: 'File to Discord & Slack',
    description:
      'When a file is uploaded, send a message in a channel and post a message in a channel',
    action: mockActions[2],
    reactions: [mockReactions[1], mockReactions[3]]
  }
]
