/**
 * Ed25519 public keys trusted to sign on-prem license files (ARCHITECTURE.md §17).
 *
 *  - `dev_only` keys are rejected when NODE_ENV=production.
 *  - The vendor's production key is baked into the bundle at build time from
 *    KADAI_VENDOR_LICENSE_KID + KADAI_VENDOR_LICENSE_PUBLIC_KEY (tsup.config.ts; set them as
 *    repository variables for the release workflows, see scripts/dev-keys/README.md). A build
 *    without them accepts no customer license: every on-prem installation stays on the Free
 *    plan. `cli issue-license keys` lists what a build trusts.
 *  - KADAI_LICENSE_PUBLIC_KEY (runtime), when set, replaces this list entirely (testing,
 *    private deployments).
 */
export interface LicensePublicKey {
  kid: string
  pem: string
  dev_only: boolean
}

/** Replaced by tsup at build time (JSON `{kid, key}` or ''); undefined when run from source. */
declare const __KADAI_VENDOR_LICENSE_KEY__: string | undefined

/**
 * Parses the build-time vendor key: JSON `{ "kid": "prod-2026", "key": "<PEM or base64 SPKI>" }`.
 * @throws on a malformed value (tsup.config.ts fails the build with the same check).
 */
export function vendorKeyFromBuild(raw: string | undefined | null): LicensePublicKey | null {
  if (!raw) return null
  const parsed = JSON.parse(raw) as { kid?: unknown; key?: unknown }
  if (typeof parsed.kid !== 'string' || !/^[a-z0-9][a-z0-9-]{1,40}$/.test(parsed.kid))
    throw new Error('vendor license key: kid must be lower-case letters, digits and dashes')
  if (typeof parsed.key !== 'string' || parsed.key.trim() === '')
    throw new Error('vendor license key: the public key is empty')
  return { kid: parsed.kid, pem: parsed.key.trim(), dev_only: false }
}

const DEV_KEYS: readonly LicensePublicKey[] = [
  {
    kid: 'dev-2026',
    dev_only: true,
    pem: `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAgnK/qrtk3dQUcZuQgedQNWvnw6E8IiiDqMe+q/X39JU=
-----END PUBLIC KEY-----
`,
  },
]

const VENDOR_KEY = vendorKeyFromBuild(
  typeof __KADAI_VENDOR_LICENSE_KEY__ === 'undefined' ? null : __KADAI_VENDOR_LICENSE_KEY__,
)

export const LICENSE_PUBLIC_KEYS: readonly LicensePublicKey[] = VENDOR_KEY
  ? [...DEV_KEYS.filter((k) => k.kid !== VENDOR_KEY.kid), VENDOR_KEY]
  : DEV_KEYS
