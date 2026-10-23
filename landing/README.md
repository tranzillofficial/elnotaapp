# ElNota standalone landing preview

Next.js application in the NEW `tranzillofficial/elnotaapp` repository. No code
from the old landing repository is changed. No existing domain is attached.

Run Node 24, `npm ci`, `npm run build`, then `npm start` in this directory.
The Vercel project uses `landing` as its root and creates preview deployments.
The design uses the provided reference screens and local Cairo font.

Routes: `/`, `/web`, `/demo`, `/privacy`, `/robots.txt`. The preview is deliberately
noindex in HTML, response headers and robots.txt. Remove preview restrictions
only as part of a separate reviewed launch, then set final canonical/sitemap.

Set server environment variable `FLUTTER_WEB_URL` to the isolated Flutter
deployment URL before building to activate the Web button. An absent value
shows an honest setup status instead of a simulated QR login.

Flutter is hosted on a separate preview origin. Its build script is
`scripts/build-web-preview.sh`, from the repository root, with output
`build/site`. It builds the normal app at `/` and a separate demo build at
`/demo/`. Set `FLUTTER_DEMO_URL` to that demo URL. The demo initializes no
Supabase client, uses its own local DB, and hard-disables cloud/admin writes,
even if their compile flags are accidentally enabled. Its records are fictional.

Normal email/password login uses the existing project's public Auth values,
as requested, without changing its schema, users, Auth settings or customer
records. Ledger sync, cloud backup and admin writes are disabled. Signing in
does not migrate or load legacy customer documents. Test QR backend deployment
still requires isolated staging; no QR function/migration was deployed.

APK and Windows links are intentionally unavailable until signed artifacts
are published. Do not point preview links at debug-signed production releases.
