'use client'
import { FormEvent, useCallback, useEffect, useState } from 'react'
import {
  CheckIcon,
  ChevronsUpDown,
  PenIcon,
  PlusIcon,
  TrashIcon
} from 'lucide-react'
import { useTranslations } from 'next-intl'
import { mockActions, mockReactions, mockServices } from '@/lib/api/mock'
import { Area } from '@/lib/api/contracts/areas'
import { Action } from '@/lib/api/contracts/actions'
import { Reaction } from '@/lib/api/contracts/reactions'
import { cn } from '@/lib/utils'
import { Button } from '../ui/button'
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle
} from '../ui/dialog'
import { Input } from '../ui/input'
import { Label } from '../ui/label'
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList
} from '../ui/command'
import { Popover, PopoverContent, PopoverTrigger } from '../ui/popover'
import {
  ComponentConfigSheet,
  type ComponentConfigState,
  type ConfigEditorTarget,
  cloneComponentConfig,
  createEmptyComponentConfig
} from './component-config-sheet'

type GroupedItems<T extends { serviceName: string }> = {
  serviceName: string
  label: string
  items: T[]
}

type ReactionField = {
  id: string
  reactionId: string
  config: ComponentConfigState | null
}

const textareaClasses =
  'border-input placeholder:text-muted-foreground selection:bg-primary selection:text-primary-foreground dark:bg-input/30 min-h-[120px] w-full rounded-md border bg-transparent px-3 py-2 text-base shadow-xs outline-none transition-[color,box-shadow] focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 md:text-sm'

const serviceDisplayNameMap = mockServices.reduce<Record<string, string>>(
  (acc, service) => {
    acc[service.name] = service.displayName
    return acc
  },
  {}
)

function getServiceKeywords(serviceName: string) {
  const keywords = [serviceName]
  const displayName = serviceDisplayNameMap[serviceName]

  if (displayName && displayName !== serviceName) {
    keywords.push(displayName)
  }

  return keywords
}

const actionsById = mockActions.reduce<Record<string, Action>>(
  (acc, action) => {
    acc[action.id] = action
    return acc
  },
  {}
)

const reactionsById = mockReactions.reduce<Record<string, Reaction>>(
  (acc, reaction) => {
    acc[reaction.id] = reaction
    return acc
  },
  {}
)

function groupItemsByService<T extends { serviceName: string }>(
  items: T[]
): GroupedItems<T>[] {
  const buckets = items.reduce<Record<string, T[]>>((acc, item) => {
    if (!acc[item.serviceName]) {
      acc[item.serviceName] = []
    }

    acc[item.serviceName].push(item)

    return acc
  }, {})

  const orderedServiceNames = [
    ...mockServices.map((service) => service.name),
    ...Object.keys(buckets).filter(
      (serviceName) => !serviceDisplayNameMap[serviceName]
    )
  ]

  return orderedServiceNames
    .map((serviceName) => {
      const groupedItems = buckets[serviceName]

      if (!groupedItems) {
        return null
      }

      return {
        serviceName,
        label: serviceDisplayNameMap[serviceName] ?? serviceName,
        items: groupedItems
      }
    })
    .filter((group): group is GroupedItems<T> => group !== null)
}

const groupedActions = groupItemsByService<Action>(mockActions)
const groupedReactions = groupItemsByService<Reaction>(mockReactions)

let reactionFieldIndex = 0
const createReactionFieldId = () => {
  reactionFieldIndex += 1
  return `reaction-${reactionFieldIndex}-${Date.now().toString(36)}`
}

const createReactionField = (): ReactionField => ({
  id: createReactionFieldId(),
  reactionId: '',
  config: null
})

const createReactionFieldsFromArea = (area: Area): ReactionField[] => {
  if (!area.reactions.length) {
    return [createReactionField()]
  }

  return area.reactions.map((reaction) => ({
    id: createReactionFieldId(),
    reactionId: reaction.id,
    config: createEmptyComponentConfig()
  }))
}

type EditAreaModalProps = {
  area: Area
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function EditAreaModal({
  area,
  open,
  onOpenChange
}: EditAreaModalProps) {
  const t = useTranslations('EditAreaModal')

  const [actionId, setActionId] = useState(() => area.action?.id ?? '')
  const [actionConfig, setActionConfig] = useState<ComponentConfigState | null>(
    () => (area.action ? createEmptyComponentConfig() : null)
  )
  const [reactionFields, setReactionFields] = useState<ReactionField[]>(() =>
    createReactionFieldsFromArea(area)
  )
  const [configEditorTarget, setConfigEditorTarget] =
    useState<ConfigEditorTarget | null>(null)
  const [areaName, setAreaName] = useState(area.name)
  const [areaDescription, setAreaDescription] = useState(area.description)

  const selectedAction = actionId ? actionsById[actionId] : undefined

  const resetForm = useCallback(() => {
    setActionId(area.action?.id ?? '')
    setActionConfig(area.action ? createEmptyComponentConfig() : null)
    setReactionFields(createReactionFieldsFromArea(area))
    setConfigEditorTarget(null)
    setAreaName(area.name)
    setAreaDescription(area.description)
  }, [area])

  useEffect(() => {
    if (!open) {
      resetForm()
    }
  }, [area, open, resetForm])

  useEffect(() => {
    if (open) {
      resetForm()
    }
  }, [open, resetForm])

  const handleDialogOpenChange = (nextOpen: boolean) => {
    if (!nextOpen) {
      resetForm()
    }

    onOpenChange(nextOpen)
  }

  const handleAddReactionField = () => {
    setReactionFields((previous) => [...previous, createReactionField()])
  }

  const handleRemoveReactionField = (id: string) => {
    setReactionFields((previous) => {
      if (previous.length === 1) {
        return previous
      }

      return previous.filter((field) => field.id !== id)
    })
    setConfigEditorTarget((current) => {
      if (current?.type === 'reaction' && current.fieldId === id) {
        return null
      }

      return current
    })
  }

  const handleReactionValueChange = (id: string, reactionId: string) => {
    setReactionFields((previous) =>
      previous.map((field) => {
        if (field.id !== id) {
          return field
        }

        if (!reactionId) {
          return {
            ...field,
            reactionId: '',
            config: null
          }
        }

        const shouldResetConfig = field.reactionId !== reactionId
        const nextConfig =
          shouldResetConfig || !field.config
            ? createEmptyComponentConfig()
            : cloneComponentConfig(field.config)

        return {
          ...field,
          reactionId,
          config: nextConfig
        }
      })
    )
    setConfigEditorTarget((current) => {
      if (!current || current.type !== 'reaction' || current.fieldId !== id) {
        return current
      }

      if (!reactionId) {
        return null
      }

      return {
        type: 'reaction',
        fieldId: id,
        componentId: reactionId
      }
    })
  }

  const handleActionValueChange = (nextActionId: string) => {
    setActionId(nextActionId)

    if (!nextActionId) {
      setActionConfig(null)
      setConfigEditorTarget((current) =>
        current?.type === 'action' ? null : current
      )
      return
    }

    setActionConfig((previous) => {
      if (actionId === nextActionId && previous) {
        return previous
      }

      return createEmptyComponentConfig()
    })

    setConfigEditorTarget((current) =>
      current?.type === 'action'
        ? { type: 'action', componentId: nextActionId }
        : current
    )
  }

  const handleOpenConfigEditorForAction = () => {
    if (!actionId) {
      return
    }

    setConfigEditorTarget({ type: 'action', componentId: actionId })
  }

  const handleOpenConfigEditorForReaction = (fieldId: string) => {
    const field = reactionFields.find(
      (reactionField) => reactionField.id === fieldId
    )

    if (!field?.reactionId) {
      return
    }

    setConfigEditorTarget({
      type: 'reaction',
      fieldId,
      componentId: field.reactionId
    })
  }

  const handleConfigOpenChange = (nextOpen: boolean) => {
    if (!nextOpen) {
      setConfigEditorTarget(null)
    }
  }

  const handleConfigSave = (config: ComponentConfigState) => {
    if (!configEditorTarget) {
      return
    }

    if (configEditorTarget.type === 'action') {
      setActionConfig(cloneComponentConfig(config))
    } else {
      setReactionFields((previous) =>
        previous.map((field) =>
          field.id === configEditorTarget.fieldId
            ? {
                ...field,
                config: cloneComponentConfig(config)
              }
            : field
        )
      )
    }

    setConfigEditorTarget(null)
  }

  const configSheetOpen = configEditorTarget !== null

  const currentReactionField =
    configEditorTarget?.type === 'reaction'
      ? reactionFields.find((field) => field.id === configEditorTarget.fieldId)
      : undefined

  const configSheetInitialConfig =
    configEditorTarget?.type === 'action'
      ? (actionConfig ?? createEmptyComponentConfig())
      : (currentReactionField?.config ?? createEmptyComponentConfig())

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    // TODO: Wire up AREA update once the backend endpoint is available.
    resetForm()
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={handleDialogOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-h-[85vh] sm:max-w-[540px]">
        <form className="space-y-6" onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>{t('title')}</DialogTitle>
            <DialogDescription>{t('subtitle')}</DialogDescription>
          </DialogHeader>

          <div className="space-y-6">
            <div className="space-y-3">
              <Label>{t('actionLabel')}</Label>
              <ActionCombobox
                value={actionId}
                placeholder={t('actionPlaceholder')}
                searchPlaceholder={t('actionsSearchPlaceholder')}
                emptyText={t('actionsEmpty')}
                ariaLabel={t('actionAriaLabel')}
                configureLabel={t('configureAction')}
                onChange={handleActionValueChange}
                onConfigure={handleOpenConfigEditorForAction}
              />
            </div>

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label>{t('reactionsLabel')}</Label>
                <span className="text-xs text-muted-foreground">
                  {t('reactionsHelper')}
                </span>
              </div>

              <div className="space-y-4">
                {reactionFields.map((field, index) => {
                  return (
                    <div key={field.id} className="space-y-2">
                      <div className="flex flex-col gap-2 sm:flex-row">
                        <ReactionCombobox
                          value={field.reactionId}
                          placeholder={t('reactionPlaceholder')}
                          searchPlaceholder={t('reactionsSearchPlaceholder')}
                          emptyText={t('reactionsEmpty')}
                          ariaLabel={t('reactionAriaLabel', {
                            index: index + 1
                          })}
                          configureLabel={t('configureReaction')}
                          onChange={(value) =>
                            handleReactionValueChange(field.id, value)
                          }
                          onConfigure={() =>
                            handleOpenConfigEditorForReaction(field.id)
                          }
                        />
                        {reactionFields.length > 1 && (
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="self-start text-muted-foreground"
                            onClick={() => handleRemoveReactionField(field.id)}
                            aria-label={t('removeReaction')}
                          >
                            <TrashIcon className="size-4" />
                          </Button>
                        )}
                      </div>
                    </div>
                  )
                })}
              </div>

              <Button
                type="button"
                variant="outline"
                className="w-full border-dashed"
                onClick={handleAddReactionField}
              >
                <PlusIcon className="mr-2 size-4" />
                {t('addReaction')}
              </Button>
            </div>

            <div className="space-y-3">
              <Label htmlFor="area-name">{t('areaNameLabel')}</Label>
              <Input
                id="area-name"
                name="areaName"
                value={areaName}
                onChange={(event) => setAreaName(event.target.value)}
                placeholder={t('areaNamePlaceholder')}
              />
            </div>

            <div className="space-y-3">
              <Label htmlFor="area-description">
                {t('areaDescriptionLabel')}
              </Label>
              <textarea
                id="area-description"
                name="areaDescription"
                value={areaDescription}
                onChange={(event) => setAreaDescription(event.target.value)}
                placeholder={t('areaDescriptionPlaceholder')}
                className={textareaClasses}
              />
            </div>
          </div>

          <DialogFooter>
            <DialogClose asChild>
              <Button type="button" variant="outline">
                {t('cancel')}
              </Button>
            </DialogClose>
            <Button type="submit">{t('submit')}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
      <ComponentConfigSheet
        open={configSheetOpen}
        onOpenChange={handleConfigOpenChange}
        target={configEditorTarget}
        selectedActionName={selectedAction?.name ?? ''}
        getReactionName={(reactionId) => reactionsById[reactionId]?.name ?? ''}
        initialConfig={configSheetInitialConfig}
        onSave={handleConfigSave}
      />
    </Dialog>
  )
}

type ActionComboboxProps = {
  value: string
  placeholder: string
  searchPlaceholder: string
  emptyText: string
  ariaLabel: string
  configureLabel: string
  onChange: (value: string) => void
  onConfigure: () => void
}

function ActionCombobox({
  value,
  placeholder,
  searchPlaceholder,
  emptyText,
  ariaLabel,
  configureLabel,
  onChange,
  onConfigure
}: ActionComboboxProps) {
  const [open, setOpen] = useState(false)
  const selectedAction = value ? actionsById[value] : undefined

  return (
    <div className="flex w-full items-center gap-2">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            type="button"
            variant="outline"
            role="combobox"
            aria-expanded={open}
            aria-label={ariaLabel}
            className="w-full flex-1 justify-between"
          >
            {selectedAction?.name ?? placeholder}
            <ChevronsUpDown className="ml-2 size-4 shrink-0 opacity-50" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-[320px] p-0" align="start">
          <Command>
            <CommandInput placeholder={searchPlaceholder} />
            <CommandList>
              <CommandEmpty>{emptyText}</CommandEmpty>
              {groupedActions.map((group) => (
                <CommandGroup key={group.serviceName} heading={group.label}>
                  {group.items.map((action) => (
                    <CommandItem
                      key={action.id}
                      value={action.id}
                      keywords={getServiceKeywords(action.serviceName)}
                      onSelect={(currentValue) => {
                        const nextValue =
                          currentValue === value ? '' : currentValue
                        onChange(nextValue)
                        setOpen(false)
                      }}
                    >
                      {action.name}
                      <CheckIcon
                        className={cn(
                          'mr-2 size-4',
                          value === action.id ? 'opacity-100' : 'opacity-0'
                        )}
                      />
                    </CommandItem>
                  ))}
                </CommandGroup>
              ))}
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
      {selectedAction ? (
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label={configureLabel}
          onClick={onConfigure}
        >
          <PenIcon className="size-4" />
        </Button>
      ) : null}
    </div>
  )
}

type ReactionComboboxProps = {
  value: string
  placeholder: string
  searchPlaceholder: string
  emptyText: string
  ariaLabel: string
  configureLabel: string
  onChange: (value: string) => void
  onConfigure: () => void
}

function ReactionCombobox({
  value,
  placeholder,
  searchPlaceholder,
  emptyText,
  ariaLabel,
  configureLabel,
  onChange,
  onConfigure
}: ReactionComboboxProps) {
  const [open, setOpen] = useState(false)
  const selectedReaction = value ? reactionsById[value] : undefined

  return (
    <div className="flex w-full flex-1 items-center gap-2">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            type="button"
            variant="outline"
            role="combobox"
            aria-expanded={open}
            aria-label={ariaLabel}
            className="w-full flex-1 justify-between"
          >
            {selectedReaction?.name ?? placeholder}
            <ChevronsUpDown className="ml-2 size-4 shrink-0 opacity-50" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-[320px] p-0" align="start">
          <Command>
            <CommandInput placeholder={searchPlaceholder} />
            <CommandList>
              <CommandEmpty>{emptyText}</CommandEmpty>
              {groupedReactions.map((group) => (
                <CommandGroup key={group.serviceName} heading={group.label}>
                  {group.items.map((reaction) => (
                    <CommandItem
                      key={reaction.id}
                      value={reaction.id}
                      keywords={getServiceKeywords(reaction.serviceName)}
                      onSelect={(currentValue) => {
                        const nextValue =
                          currentValue === value ? '' : currentValue
                        onChange(nextValue)
                        setOpen(false)
                      }}
                    >
                      {reaction.name}
                      <CheckIcon
                        className={cn(
                          'mr-2 size-4',
                          value === reaction.id ? 'opacity-100' : 'opacity-0'
                        )}
                      />
                    </CommandItem>
                  ))}
                </CommandGroup>
              ))}
            </CommandList>
          </Command>
        </PopoverContent>
      </Popover>
      {selectedReaction ? (
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label={configureLabel}
          onClick={onConfigure}
        >
          <PenIcon className="size-4" />
        </Button>
      ) : null}
    </div>
  )
}
