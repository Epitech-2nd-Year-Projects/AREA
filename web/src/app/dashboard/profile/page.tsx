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
import { useTranslations } from 'next-intl'
import { useAboutQuery, extractServices } from '@/lib/api/openapi/about'
import { mapUserDTOToUser, useCurrentUserQuery } from '@/lib/api/openapi/auth'
import { Loader2 } from 'lucide-react'
import { UserRole } from '@/lib/api/contracts/users'

const getPasswordInitialState = () => ({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

type FormStatus = {
  type: 'success' | 'error'
  message: string
} | null

function getAvatarFallback(email: string) {
  return email ? email.slice(0, 2).toUpperCase() : '??'
}

export default function ProfilePage() {
  const t = useTranslations('ProfilePage')
  const { data: userData, isLoading: isUserLoading } = useCurrentUserQuery()
  const { data: aboutData, isLoading: isAboutLoading } = useAboutQuery()

  const user = userData?.user ? mapUserDTOToUser(userData.user) : null
  const services = aboutData ? extractServices(aboutData) : []
  const connectedServices = user?.connectedServices ?? []

  const [profileForm, setProfileForm] = useState({ email: '', imageUrl: '' })
  const [passwordForm, setPasswordForm] = useState(getPasswordInitialState)
  const [profileStatus, setProfileStatus] = useState<FormStatus>(null)
  const [passwordStatus, setPasswordStatus] = useState<FormStatus>(null)
  const [avatarFileName, setAvatarFileName] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (user) {
      setProfileForm({ email: user.email, imageUrl: user.imageUrl ?? '' })
    }
  }, [user])

  useEffect(() => {
    if (!profileForm.imageUrl) return
    if (!profileForm.imageUrl.startsWith('blob:')) return
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
    if (!file) return

    const objectUrl = URL.createObjectURL(file)
    setAvatarFileName(file.name)
    setProfileStatus(null)
    setProfileForm((prev) => ({ ...prev, imageUrl: objectUrl }))
    event.target.value = ''
  }

  const handleAvatarSelectClick = () => {
    fileInputRef.current?.click()
  }

  const handleAvatarReset = () => {
    setAvatarFileName(null)
    setProfileStatus(null)
    setProfileForm((prev) => ({ ...prev, imageUrl: user?.imageUrl ?? '' }))
    if (fileInputRef.current) fileInputRef.current.value = ''
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

  const isLoading = isUserLoading || isAboutLoading

  if (isLoading || !user) {
    return (
      <div className="flex h-[60vh] flex-col items-center justify-center gap-3">
        <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
        <p className="text-muted-foreground text-sm">{t('loading')}</p>
      </div>
    )
  }

  const roleLabel =
    user.role === UserRole.Admin ? t('roleAdmin') : t('roleUser')

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
                      <AvatarFallback className="rounded-lg">
                        {getAvatarFallback(profileForm.email)}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col gap-2">
                      <div className="flex gap-2">
                        <Button
                          type="button"
                          size="sm"
                          onClick={handleAvatarSelectClick}
                        >
                          {t('avatarUploadButton')}
                        </Button>
                        <Button
                          type="button"
                          size="sm"
                          variant="outline"
                          onClick={handleAvatarReset}
                        >
                          {t('avatarResetButton')}
                        </Button>
                      </div>
                      {avatarFileName ? (
                        <p className="text-muted-foreground text-xs">
                          {avatarFileName}
                        </p>
                      ) : null}
                      <input
                        ref={fileInputRef}
                        accept="image/*"
                        type="file"
                        className="hidden"
                        onChange={handleAvatarFileChange}
                      />
                    </div>
                  </div>
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="email">{t('emailLabel')}</Label>
                  <Input
                    id="email"
                    type="email"
                    value={profileForm.email}
                    onChange={(event) =>
                      setProfileForm((prev) => ({
                        ...prev,
                        email: event.target.value
                      }))
                    }
                  />
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant="outline">{roleLabel}</Badge>
              </div>
              <div className="flex gap-2">
                <Button type="submit">{t('saveProfileButton')}</Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setProfileForm({
                      email: user.email,
                      imageUrl: user.imageUrl ?? ''
                    })
                    setProfileStatus(null)
                    setAvatarFileName(null)
                  }}
                >
                  {t('cancelProfileButton')}
                </Button>
              </div>
            </form>
            {profileStatus ? (
              <p
                className={
                  profileStatus.type === 'error'
                    ? 'text-destructive text-sm'
                    : 'text-sm text-emerald-600'
                }
                role="status"
              >
                {profileStatus.message}
              </p>
            ) : null}
          </CardContent>
        </Card>

        <Card className="flex flex-col gap-6">
          <CardHeader>
            <div>
              <CardTitle>{t('passwordSectionTitle')}</CardTitle>
              <CardDescription>
                {t('passwordSectionDescription')}
              </CardDescription>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            <form onSubmit={handlePasswordSubmit} className="space-y-4">
              <div className="grid gap-2">
                <Label htmlFor="currentPassword">
                  {t('currentPasswordLabel')}
                </Label>
                <Input
                  id="currentPassword"
                  type="password"
                  value={passwordForm.currentPassword}
                  onChange={(event) =>
                    setPasswordForm((prev) => ({
                      ...prev,
                      currentPassword: event.target.value
                    }))
                  }
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="newPassword">{t('newPasswordLabel')}</Label>
                <Input
                  id="newPassword"
                  type="password"
                  value={passwordForm.newPassword}
                  onChange={(event) =>
                    setPasswordForm((prev) => ({
                      ...prev,
                      newPassword: event.target.value
                    }))
                  }
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
                  onChange={(event) =>
                    setPasswordForm((prev) => ({
                      ...prev,
                      confirmPassword: event.target.value
                    }))
                  }
                />
              </div>
              <div className="flex gap-2">
                <Button type="submit">{t('updatePasswordButton')}</Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setPasswordForm(getPasswordInitialState())
                    setPasswordStatus(null)
                  }}
                >
                  {t('cancelPasswordButton')}
                </Button>
              </div>
            </form>
            {passwordStatus ? (
              <p
                className={
                  passwordStatus.type === 'error'
                    ? 'text-destructive text-sm'
                    : 'text-sm text-emerald-600'
                }
                role="status"
              >
                {passwordStatus.message}
              </p>
            ) : null}
          </CardContent>
        </Card>
      </div>

      <Card className="flex flex-col gap-6">
        <CardHeader>
          <div>
            <CardTitle>{t('connectedServicesTitle')}</CardTitle>
            <CardDescription>
              {t('connectedServicesDescription')}
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          {services.length ? (
            <ServiceCardList
              services={services}
              userLinkedServices={connectedServices}
              isUserAuthenticated
              isMinimal
            />
          ) : (
            <p className="text-muted-foreground text-sm">{t('noServices')}</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
