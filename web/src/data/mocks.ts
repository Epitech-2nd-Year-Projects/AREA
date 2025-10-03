import { About } from '@/lib/api/contracts/about'
import { Action } from '@/lib/api/contracts/actions'
import { Area } from '@/lib/api/contracts/areas'
import { Reaction } from '@/lib/api/contracts/reactions'
import { Service } from '@/lib/api/contracts/services'
import { User, UserRole } from '@/lib/api/contracts/users'

export const mockUserLinkedServices: string[] = ['github', 'discord']

export const mockActions: Action[] = [
  {
    id: '1',
    name: 'An issue is opened',
    description: 'An issue is opened in a repository',
    service_name: 'github'
  },
  {
    id: '8',
    name: 'A pull request is created',
    description: 'A pull request is created in a repository',
    service_name: 'github'
  },
  {
    id: '9',
    name: 'A commit is pushed',
    description: 'A commit is pushed to a branch',
    service_name: 'github'
  },
  {
    id: '2',
    name: 'A message is sent',
    description: 'A message is sent in a channel',
    service_name: 'discord'
  },
  {
    id: '10',
    name: 'A user joins a server',
    description: 'A new user joins a Discord server',
    service_name: 'discord'
  },
  {
    id: '11',
    name: 'A reaction is added',
    description: 'A user reacts to a message',
    service_name: 'discord'
  },
  {
    id: '3',
    name: 'A file is uploaded',
    description: 'A file is uploaded',
    service_name: 'onedrive'
  },
  {
    id: '12',
    name: 'A file is deleted',
    description: 'A file is deleted',
    service_name: 'onedrive'
  },
  {
    id: '13',
    name: 'A folder is shared',
    description: 'A folder is shared with another user',
    service_name: 'onedrive'
  },
  {
    id: '4',
    name: 'A message is posted',
    description: 'A message is posted in a channel',
    service_name: 'slack'
  },
  {
    id: '14',
    name: 'A user is mentioned',
    description: 'A user is mentioned in a message',
    service_name: 'slack'
  },
  {
    id: '15',
    name: 'A file is shared',
    description: 'A file is shared in a channel',
    service_name: 'slack'
  },
  {
    id: '5',
    name: 'A game is played',
    description: 'A game is played',
    service_name: 'riot'
  },
  {
    id: '16',
    name: 'A match is won',
    description: 'A player wins a match',
    service_name: 'riot'
  },
  {
    id: '17',
    name: 'A rank is updated',
    description: 'A player’s rank changes',
    service_name: 'riot'
  },
  {
    id: '6',
    name: 'A page is created',
    description: 'A new page is created in a workspace',
    service_name: 'notion'
  },
  {
    id: '18',
    name: 'A page is updated',
    description: 'A page is updated in a workspace',
    service_name: 'notion'
  },
  {
    id: '19',
    name: 'A database entry is created',
    description: 'A new entry is created in a database',
    service_name: 'notion'
  },
  {
    id: '7',
    name: 'An email is received',
    description: 'An email is received in the inbox',
    service_name: 'gmail'
  },
  {
    id: '20',
    name: 'An email is starred',
    description: 'An email is marked with a star',
    service_name: 'gmail'
  },
  {
    id: '21',
    name: 'An email is sent',
    description: 'An email is sent from the account',
    service_name: 'gmail'
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
    id: '22',
    name: 'Create a comment',
    description: 'Create a comment on an issue or pull request',
    service_name: 'github'
  },
  {
    id: '23',
    name: 'Close an issue',
    description: 'Close an open issue',
    service_name: 'github'
  },
  {
    id: '2',
    name: 'Send a message',
    description: 'Send a message in a channel',
    service_name: 'discord'
  },
  {
    id: '24',
    name: 'Kick a user',
    description: 'Remove a user from the server',
    service_name: 'discord'
  },
  {
    id: '25',
    name: 'Add a role',
    description: 'Assign a role to a user',
    service_name: 'discord'
  },
  {
    id: '3',
    name: 'Upload a file',
    description: 'Upload a file',
    service_name: 'onedrive'
  },
  {
    id: '26',
    name: 'Move a file',
    description: 'Move a file to another folder',
    service_name: 'onedrive'
  },
  {
    id: '27',
    name: 'Rename a file',
    description: 'Rename a file in storage',
    service_name: 'onedrive'
  },
  {
    id: '4',
    name: 'Post a message',
    description: 'Post a message in a channel',
    service_name: 'slack'
  },
  {
    id: '28',
    name: 'Send a direct message',
    description: 'Send a private message to a user',
    service_name: 'slack'
  },
  {
    id: '29',
    name: 'Add a reaction',
    description: 'Add a reaction to a message',
    service_name: 'slack'
  },
  {
    id: '5',
    name: 'Play a game',
    description: 'Play a game',
    service_name: 'riot'
  },
  {
    id: '30',
    name: 'Notify match result',
    description: 'Send notification with match result',
    service_name: 'riot'
  },
  {
    id: '31',
    name: 'Reward points',
    description: 'Reward points to a player',
    service_name: 'riot'
  },
  {
    id: '6',
    name: 'Create a database entry',
    description: 'Add a new entry to a database',
    service_name: 'notion'
  },
  {
    id: '32',
    name: 'Update a page',
    description: 'Update the content of a page',
    service_name: 'notion'
  },
  {
    id: '33',
    name: 'Archive a page',
    description: 'Archive an existing page',
    service_name: 'notion'
  },
  {
    id: '7',
    name: 'Send an email',
    description: 'Send an email to a recipient',
    service_name: 'gmail'
  },
  {
    id: '34',
    name: 'Forward an email',
    description: 'Forward an email to another recipient',
    service_name: 'gmail'
  },
  {
    id: '35',
    name: 'Mark as read',
    description: 'Mark an email as read',
    service_name: 'gmail'
  }
]

export const mockServices: Service[] = [
  {
    name: 'github',
    displayName: 'GitHub',
    description: 'GitHub is a web-based Git repository hosting service.',
    actions: [mockActions[0], mockActions[7], mockActions[8]],
    reactions: [mockReactions[0], mockReactions[1], mockReactions[2]]
  },
  {
    name: 'discord',
    displayName: 'Discord',
    description:
      'Discord is a cross-platform instant messaging and voice-over-IP service.',
    actions: [mockActions[1], mockActions[9], mockActions[10]],
    reactions: [mockReactions[3], mockReactions[4], mockReactions[5]]
  },
  {
    name: 'onedrive',
    displayName: 'OneDrive',
    description: 'OneDrive is a file hosting service by Microsoft.',
    actions: [mockActions[2], mockActions[11], mockActions[12]],
    reactions: [mockReactions[6], mockReactions[7], mockReactions[8]]
  },
  {
    name: 'slack',
    displayName: 'Slack',
    description: 'Slack is a team collaboration tool.',
    actions: [mockActions[3], mockActions[13], mockActions[14]],
    reactions: [mockReactions[9], mockReactions[10], mockReactions[11]]
  },
  {
    name: 'riot',
    displayName: 'Riot',
    description: 'Riot Games is a global gaming company.',
    actions: [mockActions[4], mockActions[15], mockActions[16]],
    reactions: [mockReactions[12], mockReactions[13], mockReactions[14]]
  },
  {
    name: 'notion',
    displayName: 'Notion',
    description:
      'Notion is an all-in-one workspace for notes, tasks, and databases.',
    actions: [mockActions[5], mockActions[17], mockActions[18]],
    reactions: [mockReactions[15], mockReactions[16], mockReactions[17]]
  },
  {
    name: 'gmail',
    displayName: 'Gmail',
    description: 'Gmail is a free email service developed by Google.',
    actions: [mockActions[6], mockActions[19], mockActions[20]],
    reactions: [mockReactions[18], mockReactions[19], mockReactions[20]]
  }
]

export const mockUserLinkedAreas: Area[] = [
  {
    id: '1',
    name: 'Issue to Discord',
    description:
      'When an issue is opened in a repository, send a message in a channel',
    enabled: true,
    action: mockActions[0],
    reactions: [mockReactions[1]]
  },
  {
    id: '2',
    name: 'Message to Discord',
    description:
      'When a message is sent in a channel, send a message in a channel',
    enabled: true,
    action: mockActions[1],
    reactions: [mockReactions[1]]
  },
  {
    id: '3',
    name: 'File to Discord',
    description: 'When a file is uploaded, send a message in a channel',
    enabled: false,
    action: mockActions[2],
    reactions: [mockReactions[1]]
  },
  {
    id: '4',
    name: 'File to Discord & Slack',
    description:
      'When a file is uploaded, send a message in a channel and post a message in a channel',
    enabled: true,
    action: mockActions[2],
    reactions: [mockReactions[1], mockReactions[3]]
  }
]

export type MockAreaRunStatus = 'success' | 'failure'

export type MockAreaRun = {
  id: string
  executedAt: Date
  status: MockAreaRunStatus
  durationMs: number
  reactionsTriggered: number
  errorMessage?: string
}

const mockAreaRunFailureMessages = [
  'Timeout while notifying the service',
  'Missing credential when executing the reaction',
  'Service responded with an unexpected status'
] as const

export function buildMockAreaHistory(area: Area): MockAreaRun[] {
  const seed = area.id
    .split('')
    .reduce((acc, char) => acc + char.charCodeAt(0), 0)
  const items: MockAreaRun[] = []

  for (let index = 0; index < 6; index += 1) {
    const executedAt = new Date(
      Date.now() - (index + 1) * ((seed % 6) + 2) * 60 * 60 * 1000
    )
    const isFailure = (seed + index) % 5 === 0
    const durationMs = ((seed % 4) + index + 1) * 750
    const reactionsTriggered =
      area.reactions.length === 0
        ? 0
        : ((seed + index) % area.reactions.length) + 1
    const failureMessageIndex =
      (seed + index) % mockAreaRunFailureMessages.length

    const run: MockAreaRun = {
      id: `${area.id}-run-${index}`,
      executedAt,
      status: isFailure ? 'failure' : 'success',
      durationMs,
      reactionsTriggered,
      errorMessage: isFailure
        ? mockAreaRunFailureMessages[failureMessageIndex]
        : undefined
    }

    items.push(run)
  }

  return items.sort((a, b) => b.executedAt.getTime() - a.executedAt.getTime())
}

export const mockAbout: About = {
  client: {
    host: 'https://are.na'
  },
  server: {
    currentTime: Date.now(),
    services: mockServices
  }
}

export const mockUsers: User[] = [
  {
    id: '1',
    email: 'test@test.com',
    imageUrl: 'https://example.com/image.png',
    role: UserRole.Admin,
    emailVerified: true,
    connectedServices: mockUserLinkedServices
  },
  {
    id: '2',
    email: 'test2@test.com',
    imageUrl: 'https://example.com/image2.png',
    role: UserRole.User,
    emailVerified: true,
    connectedServices: mockUserLinkedServices
  },
  {
    id: '3',
    email: 'test3@test.com',
    imageUrl: 'https://example.com/image3.png',
    role: UserRole.User,
    emailVerified: false,
    connectedServices: mockUserLinkedServices
  }
]

export const mockAuthenticatedUser: User = mockUsers[0]

const mockUserPasswords = new Map<string, string>([
  ['test@test.com', 'password123'],
  ['test2@test.com', 'password123'],
  ['test3@test.com', 'password123']
])

const mockVerificationRequests = new Map<string, number>()

const simulateNetworkDelay = async () =>
  new Promise((resolve) => {
    setTimeout(resolve, 300)
  })

type MockRegisterUserParams = {
  email: string
  password: string
}

type MockErrorCode =
  | 'EMAIL_IN_USE'
  | 'INVALID_CREDENTIALS'
  | 'USER_NOT_FOUND'
  | 'UNKNOWN'

type MockRegisterUserResult =
  | { status: 'needs-verification'; email: string }
  | {
      status: 'error'
      message: string
      code: Extract<MockErrorCode, 'EMAIL_IN_USE' | 'UNKNOWN'>
    }

export const mockRegisterUser = async ({
  email,
  password
}: MockRegisterUserParams): Promise<MockRegisterUserResult> => {
  await simulateNetworkDelay()

  const normalizedEmail = email.trim().toLowerCase()
  const existingUser = mockUsers.find(
    (user) => user.email.toLowerCase() === normalizedEmail
  )

  if (existingUser) {
    return {
      status: 'error',
      message: 'Email already in use.',
      code: 'EMAIL_IN_USE'
    }
  }

  const newUser: User = {
    id: (mockUsers.length + 1).toString(),
    email: normalizedEmail,
    role: UserRole.User,
    emailVerified: false,
    connectedServices: []
  }

  mockUsers.push(newUser)
  mockUserPasswords.set(newUser.email, password)
  mockVerificationRequests.set(newUser.email, Date.now())

  return {
    status: 'needs-verification',
    email: newUser.email
  }
}

type MockLoginParams = {
  email: string
  password: string
}

type MockLoginResult =
  | { status: 'success'; user: User }
  | { status: 'unverified'; email: string }
  | {
      status: 'error'
      message: string
      code: Extract<MockErrorCode, 'INVALID_CREDENTIALS' | 'UNKNOWN'>
    }

export const mockLoginUser = async ({
  email,
  password
}: MockLoginParams): Promise<MockLoginResult> => {
  await simulateNetworkDelay()

  const normalizedEmail = email.trim().toLowerCase()
  const user = mockUsers.find(
    (candidate) => candidate.email.toLowerCase() === normalizedEmail
  )

  if (!user) {
    return {
      status: 'error',
      message: 'Invalid email or password.',
      code: 'INVALID_CREDENTIALS'
    }
  }

  const storedPassword = mockUserPasswords.get(user.email)
  if (storedPassword && storedPassword !== password) {
    return {
      status: 'error',
      message: 'Invalid email or password.',
      code: 'INVALID_CREDENTIALS'
    }
  }

  if (!user.emailVerified) {
    mockVerificationRequests.set(user.email, Date.now())
    return {
      status: 'unverified',
      email: user.email
    }
  }

  return {
    status: 'success',
    user
  }
}

type MockResendVerificationResult =
  | { status: 'sent'; email: string }
  | {
      status: 'error'
      message: string
      code: Extract<MockErrorCode, 'USER_NOT_FOUND' | 'UNKNOWN'>
    }

export const mockResendVerificationEmail = async (
  email: string
): Promise<MockResendVerificationResult> => {
  await simulateNetworkDelay()

  const normalizedEmail = email.trim().toLowerCase()
  const user = mockUsers.find(
    (candidate) => candidate.email.toLowerCase() === normalizedEmail
  )

  if (!user) {
    return {
      status: 'error',
      message: 'No account found with that email.',
      code: 'USER_NOT_FOUND'
    }
  }

  mockVerificationRequests.set(user.email, Date.now())

  return {
    status: 'sent',
    email: user.email
  }
}

export const mockMarkUserEmailVerified = (email: string) => {
  const normalizedEmail = email.trim().toLowerCase()
  const user = mockUsers.find(
    (candidate) => candidate.email.toLowerCase() === normalizedEmail
  )

  if (user) {
    user.emailVerified = true
  }
}
