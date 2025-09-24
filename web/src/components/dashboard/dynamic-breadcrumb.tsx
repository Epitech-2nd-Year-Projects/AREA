'use client'

import * as React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator
} from '@/components/ui/breadcrumb'

type Props = {
  basePath?: string
  rootLabel?: string
  titleMap?: Record<string, string>
}

function humanize(segment: string, titleMap?: Record<string, string>) {
  if (titleMap?.[segment]) return titleMap[segment]
  const s = segment.replace(/-/g, ' ')
  return s.charAt(0).toUpperCase() + s.slice(1)
}

export default function DynamicBreadcrumb({
  basePath = '/dashboard',
  rootLabel = 'Dashboard',
  titleMap
}: Props) {
  const pathname = usePathname()

  const relative = pathname.startsWith(basePath)
    ? pathname.slice(basePath.length)
    : pathname

  const segments = relative.split('/').filter(Boolean)

  let acc = basePath === '/' ? '' : basePath

  return (
    <Breadcrumb>
      <BreadcrumbList>
        <BreadcrumbItem className="hidden md:block">
          {segments.length ? (
            <BreadcrumbLink asChild>
              <Link href={basePath || '/'}>{rootLabel}</Link>
            </BreadcrumbLink>
          ) : (
            <BreadcrumbPage>{rootLabel}</BreadcrumbPage>
          )}
        </BreadcrumbItem>
        {segments.map((seg, i) => {
          acc += `/${seg}`
          const isLast = i === segments.length - 1
          const label = humanize(seg, titleMap)

          return (
            <React.Fragment key={acc}>
              <BreadcrumbSeparator className="hidden md:block" />
              <BreadcrumbItem>
                {isLast ? (
                  <BreadcrumbPage>{label}</BreadcrumbPage>
                ) : (
                  <BreadcrumbLink asChild>
                    <Link href={acc}>{label}</Link>
                  </BreadcrumbLink>
                )}
              </BreadcrumbItem>
            </React.Fragment>
          )
        })}
      </BreadcrumbList>
    </Breadcrumb>
  )
}
