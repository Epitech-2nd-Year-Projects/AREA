'use client'
import { useEffect, useState } from 'react'
import { PlusIcon, TrashIcon } from 'lucide-react'
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

export type ConfigParamField = {
  id: string
  key: string
  value: string
}

export type ComponentConfigState = {
  secretsRef: string
  params: ConfigParamField[]
}

let configParamIndex = 0
const createConfigParamId = () => {
  configParamIndex += 1
  return `param-${configParamIndex}-${Date.now().toString(36)}`
}

export const createEmptyParamField = (): ConfigParamField => ({
  id: createConfigParamId(),
  key: '',
  value: ''
})

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
}

export function ComponentConfigSheet({
  open,
  onOpenChange,
  target,
  selectedActionName,
  getReactionName,
  initialConfig,
  onSave
}: ComponentConfigSheetProps) {
  const t = useTranslations('ComponentConfigSheet')
  const [secretsRef, setSecretsRef] = useState(initialConfig.secretsRef)
  const [params, setParams] = useState<ConfigParamField[]>(initialConfig.params)

  useEffect(() => {
    if (!open) {
      return
    }

    setSecretsRef(initialConfig.secretsRef)
    setParams(initialConfig.params.map((param) => ({ ...param })))
  }, [initialConfig, open])

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

  const handleParamChange = (
    paramId: string,
    field: 'key' | 'value',
    nextValue: string
  ) => {
    setParams((previous) =>
      previous.map((param) =>
        param.id === paramId ? { ...param, [field]: nextValue } : param
      )
    )
  }

  const handleAddParam = () => {
    setParams((previous) => [...previous, createEmptyParamField()])
  }

  const handleRemoveParam = (paramId: string) => {
    setParams((previous) => previous.filter((param) => param.id !== paramId))
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
                  <div
                    key={param.id}
                    className="flex flex-col gap-2 sm:flex-row"
                  >
                    <div className="flex-1 space-y-1">
                      <Label htmlFor={`param-${param.id}-key`}>
                        {t('paramKey')}
                      </Label>
                      <Input
                        id={`param-${param.id}-key`}
                        value={param.key}
                        onChange={(event) =>
                          handleParamChange(param.id, 'key', event.target.value)
                        }
                        placeholder={t('paramKey')}
                      />
                    </div>
                    <div className="flex-1 space-y-1">
                      <Label htmlFor={`param-${param.id}-value`}>
                        {t('paramValue')}
                      </Label>
                      <Input
                        id={`param-${param.id}-value`}
                        value={param.value}
                        onChange={(event) =>
                          handleParamChange(
                            param.id,
                            'value',
                            event.target.value
                          )
                        }
                        placeholder={t('paramValue')}
                      />
                    </div>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="self-start text-muted-foreground"
                      onClick={() => handleRemoveParam(param.id)}
                      aria-label={t('removeParam')}
                    >
                      <TrashIcon className="size-4" />
                    </Button>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-muted-foreground">
                {t('emptyParams')}
              </p>
            )}
            <Button
              type="button"
              variant="outline"
              className="w-full border-dashed"
              onClick={handleAddParam}
            >
              <PlusIcon className="mr-2 size-4" />
              {t('addParam')}
            </Button>
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
