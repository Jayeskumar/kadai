/**
 * Screens (/settings/modules): which parts of Kadai appear in the menu for this business.
 * Billing, products and settings are always on; every other module can be switched off so
 * staff see only what the shop uses. Visibility only: the plan still decides what is allowed
 * and switched-off modules keep working underneath (a bill still moves stock). The on-prem
 * Windows installer pre-selects these ("Choose the screens you need").
 */
import {
  BadgePercent,
  Barcode,
  BarChart3,
  BookOpen,
  Boxes,
  FileText,
  LayoutGrid,
  MessageSquare,
  Package,
  ShoppingCart,
  Truck,
  Users,
  Wallet,
  type LucideIcon,
} from 'lucide-react'
import { Controller, useFormContext } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { APP_MODULES, APP_MODULE_INFO, type AppModule } from '@kadai/shared/modules'
import type { TenantSettings } from '@kadai/shared/settings'
import { Badge, Button, Switch } from '@/components/ui'
import { getLanguage } from '@/lib/i18n'
import { SettingsCard } from '../components/SettingsCard'
import { SettingsFormShell } from '../components/SettingsFormShell'
import { useSettingsForm } from '../lib/use-settings-form'

const KEYS = ['modules'] as const
type Values = Pick<TenantSettings, 'modules'>

const ICONS: Readonly<Record<AppModule, LucideIcon>> = {
  inventory: Boxes,
  purchases: Truck,
  customers: Users,
  payments: Wallet,
  accounts: BookOpen,
  reports: BarChart3,
  estimates: FileText,
  promotions: BadgePercent,
  labels: Barcode,
  notifications: MessageSquare,
}

/** "Simple billing": what a small counter needs on day one. */
const SIMPLE: readonly AppModule[] = ['inventory', 'customers', 'reports']

function Presets({ disabled }: { disabled: boolean }) {
  const { t } = useTranslation('settings')
  const { setValue } = useFormContext<Values>()
  const apply = (shown: readonly AppModule[]) =>
    setValue(
      'modules.hidden',
      APP_MODULES.filter((m) => !shown.includes(m)),
      { shouldDirty: true, shouldValidate: true },
    )
  return (
    <div className="flex flex-wrap gap-2">
      <Button
        type="button"
        size="sm"
        variant="outline"
        disabled={disabled}
        onClick={() => apply(APP_MODULES)}
      >
        {t('modules.preset_all')}
      </Button>
      <Button
        type="button"
        size="sm"
        variant="outline"
        disabled={disabled}
        onClick={() => apply(SIMPLE)}
      >
        {t('modules.preset_simple')}
      </Button>
      <Button
        type="button"
        size="sm"
        variant="outline"
        disabled={disabled}
        onClick={() => apply([])}
      >
        {t('modules.preset_billing_only')}
      </Button>
    </div>
  )
}

export default function ModulesSettingsPage() {
  const { t } = useTranslation('settings')
  const api = useSettingsForm(KEYS, t('modules.saved'))
  const lng = getLanguage()
  const readOnly = !api.canEdit
  return (
    <SettingsFormShell title={t('pages.modules')} description={t('modules.description')} api={api}>
      <SettingsCard
        id="modules-core"
        icon={<ShoppingCart />}
        title={t('modules.section_core')}
        description={t('modules.section_core_hint')}
      >
        <ul className="grid gap-2 sm:grid-cols-3">
          {(
            [
              ['billing', ShoppingCart],
              ['products', Package],
              ['settings', LayoutGrid],
            ] as const
          ).map(([key, Icon]) => (
            <li
              key={key}
              className="flex items-center gap-2.5 rounded-lg border border-border bg-surface-2 px-3 py-2.5 text-sm"
            >
              <Icon className="size-4 shrink-0 text-primary" aria-hidden />
              <span className="flex-1 font-medium">{t(`modules.core_${key}`)}</span>
              <Badge tone="success">{t('modules.always_on')}</Badge>
            </li>
          ))}
        </ul>
      </SettingsCard>

      <SettingsCard
        id="modules-optional"
        icon={<LayoutGrid />}
        title={t('modules.section_optional')}
        description={t('modules.section_optional_hint')}
        actions={<Presets disabled={readOnly} />}
      >
        <Controller<Values, 'modules.hidden'>
          name="modules.hidden"
          render={({ field }) => (
            <ul className="grid gap-2 md:grid-cols-2">
              {APP_MODULES.map((m) => {
                const Icon = ICONS[m]
                const info = APP_MODULE_INFO[m]
                const shown = !field.value.includes(m)
                return (
                  <li
                    key={m}
                    className="flex items-start gap-3 rounded-lg border border-border px-3 py-3 data-[on=false]:bg-surface-2"
                    data-on={shown}
                  >
                    <span
                      className="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary-soft text-primary data-[on=false]:bg-surface-3 data-[on=false]:text-muted-foreground [&_svg]:size-4"
                      data-on={shown}
                    >
                      <Icon aria-hidden />
                    </span>
                    <div className="min-w-0 flex-1">
                      <Switch
                        checked={shown}
                        disabled={readOnly}
                        onCheckedChange={(on) =>
                          field.onChange(
                            on
                              ? field.value.filter((x) => x !== m)
                              : APP_MODULES.filter((x) => x === m || field.value.includes(x)),
                          )
                        }
                        label={info.label[lng]}
                        description={info.description[lng]}
                        aria-label={info.label[lng]}
                      />
                    </div>
                  </li>
                )
              })}
            </ul>
          )}
        />
        <p className="mt-3 text-xs text-muted-foreground">{t('modules.note')}</p>
      </SettingsCard>
    </SettingsFormShell>
  )
}
