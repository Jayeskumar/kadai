# Development license signing key — NOT SECRET, NOT FOR PRODUCTION

`license-dev-2026.private.pem` signs on-prem license files for local development and QA. Its
public key is embedded in `src/core/license-keys.ts` with `dev_only: true`, and **licenses signed
by a dev-only key are rejected when `NODE_ENV=production`**.

Release process for the vendor:

1. Generate the production keypair once, offline: `pnpm --filter @kadai/server issue-license keygen --out <safe dir> --kid prod-2026`.
2. Keep the private key in the vendor's secret store (never in this repository).
3. Put the **public** key into the release builds: GitHub → Settings → Secrets and variables →
   Actions → **Variables** (not secrets; a public key is not confidential):
   - `KADAI_VENDOR_LICENSE_KID` = `prod-2026`
   - `KADAI_VENDOR_LICENSE_PUBLIC_KEY` = the single base64 line between the `BEGIN`/`END` lines of
     `prod-2026.public.pem` (a whole PEM also works for local builds).

   `tsup` bakes it into the server bundle (`src/core/license-keys.ts`), and the Docker image, the
   native bundles and `KadaiSetup.exe` all get it. A wrong value fails the build. Check any build
   with `node apps/server/dist/cli.js issue-license keys` (exit code 3 = no production key). The
   release workflow refuses to publish a non-pre-release without one, because such a build keeps
   every shop on the Free plan.

4. Sign customer licenses with `issue-license sign --key <private.pem> --kid prod-2026 …` and
   check one with `issue-license verify --file license.json --production` against a release
   build before sending it.

Example (development):

```bash
pnpm --filter @kadai/server issue-license sign \
  --key scripts/dev-keys/license-dev-2026.private.pem --kid dev-2026 \
  --licensee "Murugan Stores" --business-name "Murugan Stores" --plan pro --max-stores 1 \
  --valid-from 2026-10-01 --valid-until 2027-09-30 --out /tmp/license.json
```
