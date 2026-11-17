import { createPublicKey } from 'node:crypto'
import { defineConfig } from 'tsup'

/**
 * The vendor's production license key, baked into the bundle (src/core/license-keys.ts):
 * KADAI_VENDOR_LICENSE_KID=prod-2026 and KADAI_VENDOR_LICENSE_PUBLIC_KEY=<PEM or base64 SPKI DER>.
 * A wrong key fails the build here instead of silently shipping a build that rejects licenses.
 */
function vendorLicenseKey(): string {
  const kid = (process.env.KADAI_VENDOR_LICENSE_KID ?? '').trim()
  const key = (process.env.KADAI_VENDOR_LICENSE_PUBLIC_KEY ?? '').trim()
  if (!kid && !key) return ''
  if (!kid || !key)
    throw new Error('set both KADAI_VENDOR_LICENSE_KID and KADAI_VENDOR_LICENSE_PUBLIC_KEY')
  if (!/^[a-z0-9][a-z0-9-]{1,40}$/.test(kid))
    throw new Error('KADAI_VENDOR_LICENSE_KID must be lower-case letters, digits and dashes')
  const parsed = key.includes('-----BEGIN')
    ? createPublicKey(key)
    : createPublicKey({ key: Buffer.from(key, 'base64'), format: 'der', type: 'spki' })
  if (parsed.asymmetricKeyType !== 'ed25519')
    throw new Error('KADAI_VENDOR_LICENSE_PUBLIC_KEY must be an Ed25519 public key')
  if (parsed.type !== 'public') throw new Error('KADAI_VENDOR_LICENSE_PUBLIC_KEY is not public')
  return JSON.stringify({ kid, key })
}

// Production bundle: one ESM file per entry point (shared code split into chunks).
// @kadai/shared is TypeScript source inside the monorepo, so it is bundled; so is `uuid`, its
// only runtime dependency the server does not declare itself. Everything else stays external and
// is resolved from apps/server/node_modules at runtime.
export default defineConfig({
  entry: {
    server: 'src/server.ts',
    worker: 'src/worker.ts',
    migrate: 'src/db/migrate-cli.ts',
    cli: 'src/cli.ts',
  },
  format: ['esm'],
  platform: 'node',
  target: 'node22',
  outDir: 'dist',
  splitting: true,
  sourcemap: true,
  clean: true,
  dts: false,
  shims: false,
  noExternal: [/^@kadai\//, 'uuid'],
  define: { __KADAI_VENDOR_LICENSE_KEY__: JSON.stringify(vendorLicenseKey()) },
})
