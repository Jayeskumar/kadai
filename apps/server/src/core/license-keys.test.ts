import { generateKeyPairSync } from 'node:crypto'
import { describe, expect, it } from 'vitest'
import { trustedLicenseKeys } from './license'
import { LICENSE_PUBLIC_KEYS, vendorKeyFromBuild } from './license-keys'

describe('vendor license key baked in at build time', () => {
  const { publicKey } = generateKeyPairSync('ed25519')
  const pem = publicKey.export({ type: 'spki', format: 'pem' }).toString()
  const base64 = publicKey.export({ type: 'spki', format: 'der' }).toString('base64')

  it('is absent when the build had none (only dev keys from source)', () => {
    expect(vendorKeyFromBuild('')).toBeNull()
    expect(vendorKeyFromBuild(undefined)).toBeNull()
    expect(LICENSE_PUBLIC_KEYS.every((k) => k.dev_only)).toBe(true)
  })

  it('accepts a PEM or the single base64 line, as a production key', () => {
    for (const key of [pem, base64]) {
      const k = vendorKeyFromBuild(JSON.stringify({ kid: 'prod-2026', key }))
      expect(k).toMatchObject({ kid: 'prod-2026', dev_only: false })
      const [trusted] = trustedLicenseKeys(null, [k!])
      expect(trusted?.key.asymmetricKeyType).toBe('ed25519')
      expect(trusted?.devOnly).toBe(false)
    }
  })

  it('rejects a malformed value', () => {
    expect(() => vendorKeyFromBuild(JSON.stringify({ kid: 'Prod 2026', key: base64 }))).toThrow()
    expect(() => vendorKeyFromBuild(JSON.stringify({ kid: 'prod-2026', key: ' ' }))).toThrow()
    expect(() => vendorKeyFromBuild('not json')).toThrow()
  })
})
