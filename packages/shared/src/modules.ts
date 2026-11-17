/**
 * App modules: the parts of Kadai a shop can switch off so that its staff see only the screens
 * it needs (a tea stall needs billing and products, not purchase orders or ledgers).
 *
 * This is about visibility, not entitlement: the plan / license still decides what is allowed
 * (features.ts) and the server keeps enforcing it. A hidden module keeps working underneath
 * (a bill still moves stock when Stock is hidden); its menu entries and screens are just gone.
 *
 * Billing (POS, bills, returns), Products and Settings are the core and cannot be hidden.
 *
 * Where it is set:
 *   - tenant settings `modules.hidden` (Settings -> Business -> Screens), changeable any time;
 *   - on-prem first-run setup seeds it from KADAI_MODULES in kadai.env, which the Windows
 *     installer writes from its "Choose the screens you need" page
 *     (deploy/onprem/windows/installer/kadai-setup.iss lists the same ids).
 */
import { z } from 'zod'

export const APP_MODULES = [
  'inventory',
  'purchases',
  'customers',
  'payments',
  'accounts',
  'reports',
  'estimates',
  'promotions',
  'labels',
  'notifications',
] as const
export type AppModule = (typeof APP_MODULES)[number]

export const AppModuleSchema = z.enum(APP_MODULES)

export function isAppModule(v: unknown): v is AppModule {
  return typeof v === 'string' && (APP_MODULES as readonly string[]).includes(v)
}

export interface AppModuleInfo {
  label: { en: string; ta: string }
  description: { en: string; ta: string }
  /** Route prefixes owned by the module (a path matches on a segment boundary). */
  paths: readonly string[]
}

export const APP_MODULE_INFO: Readonly<Record<AppModule, AppModuleInfo>> = {
  inventory: {
    label: { en: 'Stock', ta: 'சரக்கு' },
    description: {
      en: 'Stock on hand, movements, adjustments, transfers and batches',
      ta: 'கையிருப்பு, சரக்கு நகர்வு, சரிசெய்தல், மாற்றம், பேட்ச்கள்',
    },
    paths: ['/inventory'],
  },
  purchases: {
    label: { en: 'Purchases & suppliers', ta: 'கொள்முதல் & சப்ளையர்கள்' },
    description: {
      en: 'Purchase orders, StockSense reorder planner, purchase bills, suppliers',
      ta: 'கொள்முதல் ஆர்டர்கள், StockSense, கொள்முதல் பில்கள், சப்ளையர்கள்',
    },
    paths: ['/purchases', '/parties/suppliers'],
  },
  customers: {
    label: { en: 'Customers & khata', ta: 'வாடிக்கையாளர்கள் & கடன் கணக்கு' },
    description: {
      en: 'Customer list, credit (khata) balances and reminders',
      ta: 'வாடிக்கையாளர் பட்டியல், கடன் இருப்பு, நினைவூட்டல்கள்',
    },
    paths: ['/parties/customers', '/parties/doctors'],
  },
  payments: {
    label: { en: 'Payments & UPI', ta: 'பணம் & UPI' },
    description: {
      en: 'Payments received and paid, UPI collections',
      ta: 'பெற்ற / செலுத்திய பணம், UPI வசூல்',
    },
    paths: ['/payments'],
  },
  accounts: {
    label: { en: 'Accounts & expenses', ta: 'கணக்குகள் & செலவுகள்' },
    description: {
      en: 'Expenses, shifts and cash closing, day book, ledgers, statements',
      ta: 'செலவுகள், ஷிஃப்ட், நாள் புத்தகம், லெட்ஜர்கள், அறிக்கைகள்',
    },
    paths: ['/accounting'],
  },
  reports: {
    label: { en: 'Reports & GST returns', ta: 'அறிக்கைகள் & GST ரிட்டர்ன்கள்' },
    description: {
      en: 'Sales, stock and profit reports, GSTR-1 / 3B',
      ta: 'விற்பனை, சரக்கு, லாப அறிக்கைகள், GSTR-1 / 3B',
    },
    paths: ['/reports'],
  },
  estimates: {
    label: { en: 'Estimates', ta: 'மதிப்பீடுகள்' },
    description: {
      en: 'Quotations that become bills later',
      ta: 'பின்னர் பில்லாக மாறும் விலைப்புள்ளிகள்',
    },
    paths: ['/sales/estimates'],
  },
  promotions: {
    label: { en: 'Offers & schemes', ta: 'சலுகைகள் & திட்டங்கள்' },
    description: {
      en: 'Discounts, buy-x-get-y and combo offers',
      ta: 'தள்ளுபடி, ஒன்று வாங்கினால் ஒன்று, காம்போ சலுகைகள்',
    },
    paths: ['/catalog/promotions'],
  },
  labels: {
    label: { en: 'Barcode labels', ta: 'பார்கோடு லேபிள்கள்' },
    description: {
      en: 'Design and print barcode / price labels',
      ta: 'பார்கோடு / விலை லேபிள்கள் அச்சிடுதல்',
    },
    paths: ['/catalog/labels'],
  },
  notifications: {
    label: { en: 'WhatsApp & SMS', ta: 'வாட்ஸ்அப் & SMS' },
    description: {
      en: 'Bills and reminders by WhatsApp / SMS, message log',
      ta: 'வாட்ஸ்அப் / SMS மூலம் பில்கள், நினைவூட்டல்கள்',
    },
    paths: ['/notifications', '/settings/notifications'],
  },
}

function matchesPrefix(path: string, prefix: string): boolean {
  return path === prefix || path.startsWith(`${prefix}/`)
}

/** The hidden module that owns `path`, or null when the path is visible. */
export function hiddenModuleForPath(path: string, hidden: readonly AppModule[]): AppModule | null {
  for (const m of hidden) {
    if (APP_MODULE_INFO[m].paths.some((p) => matchesPrefix(path, p))) return m
  }
  return null
}

/**
 * Parses KADAI_MODULES (the modules to SHOW, comma or space separated; empty or "all" shows
 * everything) into the `modules.hidden` list. Unknown names are returned in `unknown` and
 * otherwise ignored, so a typo in kadai.env never stops the server.
 */
export function parseEnabledModules(raw: string | null | undefined): {
  hidden: AppModule[]
  unknown: string[]
} {
  const value = (raw ?? '').trim().toLowerCase()
  if (value === '' || value === 'all') return { hidden: [], unknown: [] }
  const names = value.split(/[\s,;]+/).filter(Boolean)
  const unknown = names.filter((n) => !isAppModule(n) && n !== 'none')
  const enabled = new Set(names.filter(isAppModule))
  return { hidden: APP_MODULES.filter((m) => !enabled.has(m)), unknown }
}
