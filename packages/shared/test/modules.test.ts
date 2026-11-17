import { describe, expect, it } from 'vitest'
import {
  APP_MODULES,
  APP_MODULE_INFO,
  hiddenModuleForPath,
  parseEnabledModules,
} from '../src/modules'
import {
  TenantSettingsPatchSchema,
  mergeSettings,
  readSettings,
  DEFAULT_SETTINGS,
} from '../src/settings'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

describe('app modules', () => {
  it('parses KADAI_MODULES (modules to show) into the hidden list', () => {
    expect(parseEnabledModules(undefined)).toEqual({ hidden: [], unknown: [] })
    expect(parseEnabledModules('  ')).toEqual({ hidden: [], unknown: [] })
    expect(parseEnabledModules('ALL')).toEqual({ hidden: [], unknown: [] })
    expect(parseEnabledModules('none')).toEqual({ hidden: [...APP_MODULES], unknown: [] })
    const r = parseEnabledModules('Inventory; reports  customers,typo')
    expect(r.unknown).toEqual(['typo'])
    expect(r.hidden).toEqual(
      APP_MODULES.filter((m) => !['inventory', 'reports', 'customers'].includes(m)),
    )
  })

  it('maps paths to the hidden module that owns them, on segment boundaries', () => {
    expect(hiddenModuleForPath('/inventory/stock', ['inventory'])).toBe('inventory')
    expect(hiddenModuleForPath('/inventory', ['inventory'])).toBe('inventory')
    expect(hiddenModuleForPath('/inventory-x', ['inventory'])).toBeNull()
    expect(hiddenModuleForPath('/parties/suppliers/42', ['purchases'])).toBe('purchases')
    expect(hiddenModuleForPath('/parties/customers', ['purchases'])).toBeNull()
    expect(hiddenModuleForPath('/settings/notifications', ['notifications'])).toBe('notifications')
    expect(hiddenModuleForPath('/pos', [...APP_MODULES])).toBeNull()
    expect(hiddenModuleForPath('/catalog/products', [...APP_MODULES])).toBeNull()
    expect(hiddenModuleForPath('/settings/modules', [...APP_MODULES])).toBeNull()
  })

  it('never lets two modules own the same path', () => {
    const prefixes = APP_MODULES.flatMap((m) => APP_MODULE_INFO[m].paths)
    expect(new Set(prefixes).size).toBe(prefixes.length)
  })

  it('stores modules.hidden in tenant settings (default: everything shown)', () => {
    expect(DEFAULT_SETTINGS.modules.hidden).toEqual([])
    const next = mergeSettings(DEFAULT_SETTINGS, { modules: { hidden: ['accounts', 'labels'] } })
    expect(next.modules.hidden).toEqual(['accounts', 'labels'])
    expect(() =>
      mergeSettings(DEFAULT_SETTINGS, { modules: { hidden: ['accounts', 'accounts'] } }),
    ).toThrow()
    expect(TenantSettingsPatchSchema.safeParse({ modules: { hidden: ['nope'] } }).success).toBe(
      false,
    )
    // Old or hand-edited JSON never breaks reads.
    expect(readSettings({ modules: { hidden: ['nope'] } }).modules.hidden).toEqual([])
    expect(readSettings({}).modules.hidden).toEqual([])
  })

  it('is offered by the Windows installer with the same module ids', () => {
    const iss = readFileSync(
      fileURLToPath(
        new URL('../../../deploy/onprem/windows/installer/kadai-setup.iss', import.meta.url),
      ),
      'utf8',
    )
    const block = /\/\/ BEGIN APP_MODULES\n([\s\S]*?)\/\/ END APP_MODULES/.exec(iss)?.[1] ?? ''
    const ids = [...block.matchAll(/'([a-z_]+)'/g)].map((m) => m[1])
    expect(ids).toEqual([...APP_MODULES])
  })
})
