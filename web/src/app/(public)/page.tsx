import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'

const featureKeys = ['instantTriggers', 'unifiedData', 'teamReady'] as const

export default function Home() {
  const t = useTranslations('HomePage')
  const currentYear = new Date().getFullYear()

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-16">
      <section className="flex flex-col items-center gap-10 text-center">
        <span className="rounded-full border border-transparent bg-muted px-4 py-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          {t('badgeLabel')}
        </span>
        <div className="flex flex-col gap-4">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">{t('headline')}</h1>
          <p className="text-muted-foreground text-lg">{t('subheadline')}</p>
        </div>
        <div className="flex flex-col items-center gap-3 sm:flex-row">
          <Button asChild size="lg" className="w-full sm:w-auto">
            <Link href="/login">{t('primaryCta')}</Link>
          </Button>
          <Button asChild variant="outline" size="lg" className="w-full sm:w-auto">
            <Link href="/explore">{t('secondaryCta')}</Link>
          </Button>
        </div>
      </section>

      <section className="grid gap-6 md:grid-cols-3">
        {featureKeys.map((key) => (
          <div key={key} className="flex h-full flex-col gap-3 rounded-2xl border bg-card p-6">
            <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
              <span className="h-2 w-2 rounded-full bg-primary" aria-hidden />
              {t(`features.${key}.title`)}
            </div>
            <p className="text-sm text-muted-foreground leading-relaxed">
              {t(`features.${key}.description`)}
            </p>
          </div>
        ))}
      </section>

      <section className="overflow-hidden rounded-3xl border bg-gradient-to-br from-primary/5 via-background to-secondary/20 p-10">
        <div className="flex flex-col items-center gap-6 text-center">
          <h2 className="text-2xl font-semibold tracking-tight sm:text-3xl">{t('cta.title')}</h2>
          <p className="max-w-2xl text-muted-foreground text-base">{t('cta.description')}</p>
          <Button asChild size="lg" variant="secondary" className="gap-2">
            <Link href="/contact">
              {t('cta.button')}
              <ArrowRight className="h-4 w-4" aria-hidden />
            </Link>
          </Button>
        </div>
      </section>

      <footer className="flex flex-col items-center gap-2 text-sm text-muted-foreground sm:flex-row sm:justify-between sm:text-left">
        <p>{t('footer.copy', { year: currentYear })}</p>
        <div className="flex items-center gap-4">
          <Link href="/about" className="transition hover:text-foreground">
            {t('footer.links.about')}
          </Link>
          <Link href="/explore" className="transition hover:text-foreground">
            {t('footer.links.explore')}
          </Link>
          <Link href="/contact" className="transition hover:text-foreground">
            {t('footer.links.contact')}
          </Link>
        </div>
      </footer>
    </div>
  )
}
