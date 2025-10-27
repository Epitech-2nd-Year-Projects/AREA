'use client'
import { useEffect, useMemo, useState } from 'react'
import { useTranslations } from 'next-intl'
import { Button } from '../ui/button'
import { Input } from '../ui/input'
import { Label } from '../ui/label'
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle
} from '../ui/sheet'
import type { ComponentParameterDTO } from '@/lib/api/contracts/openapi/areas'
import { useIdentitiesQuery } from '@/lib/api/openapi/auth'
import type { IdentitySummaryDTO } from '@/lib/api/contracts/openapi/auth'

export type ConfigParamField = {
  id: string
  key: string
  value: string
  label?: string
  description?: string
  required?: boolean
  type?: ComponentParameterDTO['type']
}

export type ComponentConfigState = {
  secretsRef: string
  params: ConfigParamField[]
}

export const createEmptyComponentConfig = (): ComponentConfigState => ({
  secretsRef: '',
  params: []
})

export const cloneComponentConfig = (
  config: ComponentConfigState
): ComponentConfigState => ({
  secretsRef: config.secretsRef,
  params: config.params.map((param) => ({ ...param }))
})

export type ConfigEditorTarget =
  | { type: 'action'; componentId: string }
  | { type: 'reaction'; fieldId: string; componentId: string }

export type ComponentConfigSheetProps = {
  open: boolean
  onOpenChange: (open: boolean) => void
  target: ConfigEditorTarget | null
  selectedActionName: string
  getReactionName: (reactionId: string) => string
  initialConfig: ComponentConfigState
  onSave: (config: ComponentConfigState) => void
  getComponentParameters: (componentId: string) => ComponentParameterDTO[]
}

export function ComponentConfigSheet({
  open,
  onOpenChange,
  target,
  selectedActionName,
  getReactionName,
  initialConfig,
  onSave,
  getComponentParameters
}: ComponentConfigSheetProps) {
  const t = useTranslations('ComponentConfigSheet')
  const [secretsRef, setSecretsRef] = useState(initialConfig.secretsRef)
  const [params, setParams] = useState<ConfigParamField[]>(initialConfig.params)
  const componentParameters = useMemo(() => {
    if (!target) {
      return [] as ComponentParameterDTO[]
    }
    const parameters = getComponentParameters(target.componentId)
    if (!Array.isArray(parameters) || parameters.length === 0) {
      return [] as ComponentParameterDTO[]
    }
    return parameters.filter((parameter) => parameter.key.trim().length > 0)
  }, [getComponentParameters, target])

  const { data: identitiesData } = useIdentitiesQuery({
    enabled: open
  })
  const identitySummaries = useMemo(
    () => identitiesData?.identities ?? [],
    [identitiesData]
  )

  const identitiesByProvider = useMemo(() => {
    const map = new Map<string, IdentitySummaryDTO[]>()
    for (const identity of identitySummaries) {
      const providerKey = identity.provider.trim().toLowerCase()
      const existing = map.get(providerKey)
      if (existing) {
        existing.push(identity)
      } else {
        map.set(providerKey, [identity])
      }
    }
    return map
  }, [identitySummaries])

  const identitiesById = useMemo(() => {
    const map = new Map<string, IdentitySummaryDTO>()
    for (const identity of identitySummaries) {
      map.set(identity.id, identity)
    }
    return map
  }, [identitySummaries])

  const componentParametersByKey = useMemo(() => {
    const map = new Map<string, ComponentParameterDTO>()
    for (const definition of componentParameters) {
      const key = definition.key.trim()
      if (!key) {
        continue
      }
      map.set(key, definition)
    }
    return map
  }, [componentParameters])

  useEffect(() => {
    if (!open) {
      return
    }

    setSecretsRef(initialConfig.secretsRef)
    if (componentParameters.length > 0) {
      const valuesByKey = new Map<string, string>()
      for (const param of initialConfig.params) {
        if (param.key) {
          valuesByKey.set(param.key, param.value)
        }
      }

      const definitionKeys = new Set<string>()
      const definitionFields: ConfigParamField[] = componentParameters.map(
        (definition) => {
          const key = definition.key.trim()
          definitionKeys.add(key)
          const label =
            typeof definition.label === 'string' &&
            definition.label.trim().length
              ? definition.label
              : key
          const description =
            typeof definition.description === 'string'
              ? definition.description
              : undefined
          return {
            id: key,
            key,
            value: valuesByKey.get(key) ?? '',
            label,
            description,
            required: Boolean(definition.required),
            type: definition.type
          }
        }
      )

      const customFields = initialConfig.params
        .filter((param) => param.key && !definitionKeys.has(param.key))
        .map((param) => ({
          id: param.id || param.key,
          key: param.key,
          value: param.value,
          label: param.label ?? param.key,
          description: param.description,
          required: param.required,
          type: param.type
        }))

      setParams([...definitionFields, ...customFields])
      return
    }

    setParams(initialConfig.params.map((param) => ({ ...param })))
  }, [componentParameters, initialConfig, open])

  useEffect(() => {
    if (!open || identitySummaries.length === 0) {
      return
    }

    setParams((previous) => {
      let changed = false

      const next = previous.map((param) => {
        const paramType =
          typeof param.type === 'string' ? param.type.toLowerCase() : ''

        if (paramType !== 'identity') {
          return param
        }

        if (param.value.trim().length > 0) {
          return param
        }

        const definition = componentParametersByKey.get(param.key)
        const provider =
          typeof definition?.provider === 'string'
            ? definition.provider.trim().toLowerCase()
            : undefined

        let identity: IdentitySummaryDTO | undefined
        if (provider) {
          identity = identitiesByProvider.get(provider)?.[0]
        } else {
          identity = identitySummaries[0]
        }

        if (!identity) {
          return param
        }

        if (param.value === identity.id) {
          return param
        }

        changed = true
        return { ...param, value: identity.id }
      })

      return changed ? next : previous
    })
  }, [componentParametersByKey, identitiesByProvider, identitySummaries, open])

  const isActionTarget = target?.type === 'action'
  const isReactionTarget = target?.type === 'reaction'
  const resolvedComponentName = isActionTarget
    ? selectedActionName || t('fallbackActionName')
    : isReactionTarget
      ? getReactionName(target.componentId) || t('fallbackReactionName')
      : ''

  const sheetTitle = isActionTarget
    ? t('titleAction', { componentName: resolvedComponentName })
    : isReactionTarget
      ? t('titleReaction', { componentName: resolvedComponentName })
      : ''

  const sheetDescription = isActionTarget
    ? t('descriptionAction')
    : isReactionTarget
      ? t('descriptionReaction')
      : ''

  const handleParamValueChange = (paramId: string, nextValue: string) => {
    setParams((previous) =>
      previous.map((param) =>
        param.id === paramId ? { ...param, value: nextValue } : param
      )
    )
  }

  const handleSave = () => {
    onSave({
      secretsRef: secretsRef.trim(),
      params: params.map((param) => ({ ...param }))
    })
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="sm:max-w-md">
        <SheetHeader>
          <SheetTitle>{sheetTitle}</SheetTitle>
          <SheetDescription>{sheetDescription}</SheetDescription>
        </SheetHeader>
        <div className="flex-1 space-y-6 overflow-y-auto px-4 pb-4">
          <div className="space-y-2">
            <Label htmlFor="component-secrets-ref">
              {t('secretsRefLabel')}
            </Label>
            <Input
              id="component-secrets-ref"
              value={secretsRef}
              onChange={(event) => setSecretsRef(event.target.value)}
              placeholder={t('secretsRefPlaceholder')}
            />
          </div>
          <div className="space-y-3">
            <div className="space-y-1">
              <Label>{t('paramsLabel')}</Label>
              <p className="text-xs text-muted-foreground">
                {t('paramsHelper')}
              </p>
            </div>
            {params.length > 0 ? (
              <div className="space-y-3">
                {params.map((param) => {
                  const paramType =
                    typeof param.type === 'string'
                      ? param.type.toLowerCase()
                      : ''
                  const isIdentityParam = paramType === 'identity'
                  const identitySummary =
                    isIdentityParam && param.value
                      ? identitiesById.get(param.value)
                      : undefined

                  return (
                    <div key={param.id} className="space-y-2">
                      <div className="space-y-1">
                        <Label htmlFor={`param-${param.id}-value`}>
                          {(param.label ?? param.key) +
                            (param.required ? ' *' : '')}
                        </Label>
                        <p className="text-xs text-muted-foreground">
                          {t('paramKey')}: {param.key}
                        </p>
                        {param.description ? (
                          <p className="text-xs text-muted-foreground">
                            {param.description}
                          </p>
                        ) : null}
                      </div>
                      <Input
                        id={`param-${param.id}-value`}
                        value={param.value}
                        onChange={(event) =>
                          handleParamValueChange(param.id, event.target.value)
                        }
                        placeholder={
                          isIdentityParam
                            ? t('identityValuePlaceholder')
                            : t('paramValue')
                        }
                        readOnly={isIdentityParam}
                        disabled={isIdentityParam}
                      />
                      {isIdentityParam ? (
                        <p className="text-xs text-muted-foreground">
                          {identitySummary
                            ? t('identityResolvedHelper', {
                                subject:
                                  identitySummary.subject || identitySummary.id
                              })
                            : t('identityUnresolvedHelper')}
                        </p>
                      ) : null}
                    </div>
                  )
                })}
              </div>
            ) : (
              <p className="text-xs text-muted-foreground">
                {t('emptyParams')}
              </p>
            )}
          </div>
        </div>
        <SheetFooter>
          <SheetClose asChild>
            <Button type="button" variant="outline">
              {t('cancel')}
            </Button>
          </SheetClose>
          <Button type="button" onClick={handleSave}>
            {t('save')}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
