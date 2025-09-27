'use client'

import type { ChangeEvent, FormEvent } from 'react'
import { useEffect, useRef, useState } from 'react'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { ServiceCardList } from '@/components/services/service-card-list'
import { mockServices, mockAuthenticatedUser } from '@/data/mocks'
import { UserRole } from '@/lib/api/contracts/users'
import { useTranslations } from 'next-intl'

type FormStatus = {
  type: 'success' | 'error'
  message: string
} | null

const DEFAULT_AVATAR_URL = mockAuthenticatedUser.imageUrl ?? ''

const getProfileInitialState = () => ({
  email: mockAuthenticatedUser.email,
  imageUrl: DEFAULT_AVATAR_URL
})

const getPasswordInitialState = () => ({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

function getAvatarFallback(email: string) {
  return email ? email.slice(0, 2).toUpperCase() : '??'
}

export default function ProfilePage() {
  const t = useTranslations('ProfilePage')
  const [profileForm, setProfileForm] = useState(getProfileInitialState)
  const [passwordForm, setPasswordForm] = useState(getPasswordInitialState)
  const [profileStatus, setProfileStatus] = useState<FormStatus>(null)
  const [passwordStatus, setPasswordStatus] = useState<FormStatus>(null)
  const [avatarFileName, setAvatarFileName] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  const roleLabel =
    mockAuthenticatedUser.role === UserRole.Admin
      ? t('roleAdmin')
      : t('roleUser')

  useEffect(() => {
    if (!profileForm.imageUrl) {
      return
    }

    if (!profileForm.imageUrl.startsWith('blob:')) {
      return
    }

    return () => {
      URL.revokeObjectURL(profileForm.imageUrl)
    }
  }, [profileForm.imageUrl])

  const handleProfileSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setPasswordStatus(null)
    setProfileStatus({ type: 'success', message: t('profileSaved') })
  }

  const handleAvatarFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]

    if (!file) {
      return
    }

    const objectUrl = URL.createObjectURL(file)
    setAvatarFileName(file.name)
    setProfileStatus(null)
    setProfileForm((prev) => ({
      ...prev,
      imageUrl: objectUrl
    }))

    event.target.value = ''
  }

  const handleAvatarSelectClick = () => {
    fileInputRef.current?.click()
  }

  const handleAvatarReset = () => {
    setAvatarFileName(null)
    setProfileStatus(null)
    setProfileForm((prev) => ({
      ...prev,
      imageUrl: DEFAULT_AVATAR_URL
    }))

    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  const handlePasswordSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (
      !passwordForm.currentPassword ||
      !passwordForm.newPassword ||
      !passwordForm.confirmPassword
    ) {
      setPasswordStatus({ type: 'error', message: t('passwordMissing') })
      return
    }

    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      setPasswordStatus({ type: 'error', message: t('passwordMismatch') })
      return
    }

    setProfileStatus(null)
    setPasswordStatus({ type: 'success', message: t('passwordUpdated') })
    setPasswordForm(getPasswordInitialState())
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">{t('pageTitle')}</h1>
        <p className="text-muted-foreground text-sm">{t('pageDescription')}</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <Card className="flex flex-col gap-6">
          <CardHeader>
            <div>
              <CardTitle>{t('profileInformationTitle')}</CardTitle>
              <CardDescription>
                {t('profileInformationDescription')}
              </CardDescription>
            </div>
          </CardHeader>
          <CardContent className="space-y-10">
            <form onSubmit={handleProfileSubmit} className="space-y-6">
              <div className="grid gap-4">
                <div className="grid gap-2">
                  <Label>{t('avatarUploadLabel')}</Label>
                  <div className="flex flex-col items-start gap-4">
                    <Avatar className="size-24 rounded-lg">
                      <AvatarImage src={profileForm.imageUrl} alt="" />
                      <AvatarFallback className="rounded-lg text-base font-medium">
                        {getAvatarFallback(profileForm.email)}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col gap-2">
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept="image/*"
                        className="hidden"
                        onChange={handleAvatarFileChange}
                      />
                      <div className="flex flex-wrap gap-2">
                        <Button
                          type="button"
                          variant="outline"
                          onClick={handleAvatarSelectClick}
                          className="cursor-pointer"
                        >
                          {t('avatarUploadButton')}
                        </Button>
                        {profileForm.imageUrl !== DEFAULT_AVATAR_URL ? (
                          <Button
                            type="button"
                            variant="ghost"
                            onClick={handleAvatarReset}
                            className="cursor-pointer"
                          >
                            {t('avatarResetButton')}
                          </Button>
                        ) : null}
                      </div>
                      <p className="text-muted-foreground text-xs">
                        {t('avatarHelper')}
                        {avatarFileName
                          ? ` ${t('avatarFileSelected', { fileName: avatarFileName })}`
                          : ''}
                      </p>
                    </div>
                  </div>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="email">{t('emailLabel')}</Label>
                  <Input
                    id="email"
                    type="email"
                    value={profileForm.email}
                    onChange={(event) => {
                      setProfileForm((prev) => ({
                        ...prev,
                        email: event.target.value
                      }))
                      setProfileStatus(null)
                    }}
                    required
                  />
                </div>
              </div>

              {profileStatus ? (
                <p
                  className={`text-sm ${
                    profileStatus.type === 'success'
                      ? 'text-emerald-600'
                      : 'text-destructive'
                  }`}
                >
                  {profileStatus.message}
                </p>
              ) : null}

              <div className="flex justify-end">
                <Button type="submit" className="cursor-pointer">
                  {t('saveChanges')}
                </Button>
              </div>
            </form>

            <form onSubmit={handlePasswordSubmit} className="space-y-6">
              <div className="space-y-1">
                <h2 className="text-lg font-semibold">{t('passwordTitle')}</h2>
                <p className="text-muted-foreground text-sm">
                  {t('passwordDescription')}
                </p>
              </div>
              <div className="grid gap-4 sm:grid-cols-3">
                <div className="grid gap-2">
                  <Label htmlFor="currentPassword">
                    {t('currentPasswordLabel')}
                  </Label>
                  <Input
                    id="currentPassword"
                    type="password"
                    value={passwordForm.currentPassword}
                    onChange={(event) => {
                      setPasswordForm((prev) => ({
                        ...prev,
                        currentPassword: event.target.value
                      }))
                      setPasswordStatus(null)
                    }}
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="newPassword">{t('newPasswordLabel')}</Label>
                  <Input
                    id="newPassword"
                    type="password"
                    value={passwordForm.newPassword}
                    onChange={(event) => {
                      setPasswordForm((prev) => ({
                        ...prev,
                        newPassword: event.target.value
                      }))
                      setPasswordStatus(null)
                    }}
                    required
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="confirmPassword">
                    {t('confirmPasswordLabel')}
                  </Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    value={passwordForm.confirmPassword}
                    onChange={(event) => {
                      setPasswordForm((prev) => ({
                        ...prev,
                        confirmPassword: event.target.value
                      }))
                      setPasswordStatus(null)
                    }}
                    required
                  />
                </div>
              </div>

              {passwordStatus ? (
                <p
                  className={`text-sm ${
                    passwordStatus.type === 'success'
                      ? 'text-emerald-600'
                      : 'text-destructive'
                  }`}
                >
                  {passwordStatus.message}
                </p>
              ) : null}

              <div className="flex justify-end">
                <Button type="submit" className="cursor-pointer">
                  {t('updatePassword')}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        <Card className="h-fit">
          <CardHeader>
            <CardTitle>{t('accountDetailsTitle')}</CardTitle>
            <CardDescription>{t('accountDetailsDescription')}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid gap-2">
              <span className="text-sm font-medium">{t('roleLabel')}</span>
              <Badge variant="secondary" className="w-fit">
                {roleLabel}
              </Badge>
            </div>
            <div className="grid gap-2">
              <span className="text-sm font-medium">
                {t('connectedServicesTitle')}
              </span>
              {mockAuthenticatedUser.connectedServices.length ? (
                <ServiceCardList
                  services={mockServices.filter((service) =>
                    mockAuthenticatedUser.connectedServices.includes(
                      service.name
                    )
                  )}
                  userLinkedServices={mockAuthenticatedUser.connectedServices}
                  isUserAuthenticated
                  isMinimal
                />
              ) : (
                <span className="text-muted-foreground text-sm">
                  {t('emptyServices')}
                </span>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
