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
                {params.map((param) => (
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
                      placeholder={t('paramValue')}
                    />
                  </div>
                ))}
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
