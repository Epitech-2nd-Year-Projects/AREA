'use client'
import { useEffect, useState } from 'react'
import { useTheme } from 'next-themes'
import { useTranslations } from 'next-intl'
import { Area } from '@/lib/api/contracts/areas'
import {
  ChevronDownIcon,
  CopyIcon,
  PenIcon,
  PlayIcon,
  PowerIcon,
  TrashIcon
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from '../ui/card'
import { MagicCard } from '../ui/magic-card'
import { Button } from '../ui/button'
import { Tooltip, TooltipContent, TooltipTrigger } from '../ui/tooltip'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger
} from '../ui/dropdown-menu'
import { EditAreaModal } from './edit-area-modal'
import { TestRunAreaModal } from './test-run-area-modal'
import { DuplicateAreaModal } from './duplicate-area-modal'
import { DeleteAreaModal } from './delete-area-modal'

type AreaCardProps = {
  area: Area
}

export function AreaCard({ area }: AreaCardProps) {
  const t = useTranslations('AreaCard')
  const { theme } = useTheme()
  const [isEnabled, setIsEnabled] = useState(area.enabled)
  const [isTestRunOpen, setIsTestRunOpen] = useState(false)
  const [isEditOpen, setIsEditOpen] = useState(false)
  const [isDuplicateOpen, setIsDuplicateOpen] = useState(false)
  const [isDeleteOpen, setIsDeleteOpen] = useState(false)

  useEffect(() => {
    setIsEnabled(area.enabled)
  }, [area.enabled])

  const toggleLabel = isEnabled ? t('disableArea') : t('enableArea')

  return (
    <>
      <Card
        className="h-full w-full gap-0 border-none p-0 shadow-none"
        aria-disabled={!isEnabled}
      >
        <MagicCard
          gradientColor={theme === 'dark' ? '#262626' : '#D9D9D955'}
          className={cn(
            'h-full transition-[opacity,filter] duration-200',
            !isEnabled && 'opacity-60 saturate-[0.85]'
          )}
          innerClassName="flex h-full w-full flex-col"
        >
          <CardHeader className="border-b border-border p-4 [.border-b]:pb-4">
            <CardTitle>{area.name}</CardTitle>
            <CardAction className="flex items-center gap-2">
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    variant={isEnabled ? 'secondary' : 'outline'}
                    size="icon"
                    className="size-8 cursor-pointer"
                    aria-label={toggleLabel}
                    onClick={() => setIsEnabled((prev) => !prev)}
                  >
                    <PowerIcon
                      className={cn(
                        'size-4',
                        !isEnabled && 'text-muted-foreground'
                      )}
                    />
                  </Button>
                </TooltipTrigger>
                <TooltipContent>
                  <p>{toggleLabel}</p>
                </TooltipContent>
              </Tooltip>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="secondary"
                    size="sm"
                    className="cursor-pointer gap-2"
                    aria-label={t('openActions')}
                  >
                    {t('actionsLabel')}
                    <ChevronDownIcon className="size-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-44">
                  <DropdownMenuItem onSelect={() => setIsTestRunOpen(true)}>
                    <PlayIcon className="size-4" />
                    {t('testRunArea')}
                  </DropdownMenuItem>
                  <DropdownMenuItem onSelect={() => setIsEditOpen(true)}>
                    <PenIcon className="size-4" />
                    {t('editArea')}
                  </DropdownMenuItem>
                  <DropdownMenuItem onSelect={() => setIsDuplicateOpen(true)}>
                    <CopyIcon className="size-4" />
                    {t('duplicateArea')}
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    variant="destructive"
                    onSelect={() => setIsDeleteOpen(true)}
                  >
                    <TrashIcon className="size-4" />
                    {t('deleteArea')}
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </CardAction>
          </CardHeader>
          <CardContent className="flex-1 p-4">
            <CardDescription>{area.description}</CardDescription>
          </CardContent>
        </MagicCard>
      </Card>
      <TestRunAreaModal
        area={area}
        open={isTestRunOpen}
        onOpenChange={setIsTestRunOpen}
      />
      <EditAreaModal
        area={area}
        open={isEditOpen}
        onOpenChange={setIsEditOpen}
      />
      <DuplicateAreaModal
        areaName={area.name}
        open={isDuplicateOpen}
        onOpenChange={setIsDuplicateOpen}
      />
      <DeleteAreaModal
        areaName={area.name}
        open={isDeleteOpen}
        onOpenChange={setIsDeleteOpen}
      />
    </>
  )
}
