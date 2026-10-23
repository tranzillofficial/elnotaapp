# ElNota standalone landing preview

Next.js application in the NEW `tranzillofficial/elnotaapp` repository. No code
from the old landing repository is changed. No existing domain is attached.

Run Node 24, `npm ci`, `npm run build`, then `npm start` in this directory.
The Vercel project uses `landing` as its root and creates preview deployments.
The design uses the provided reference screens and local Cairo font.

Routes: `/`, `/web`, `/privacy`, `/robots.txt`. The preview is deliberately
noindex in HTML, response headers and robots.txt. Remove preview restrictions
only as part of a separate reviewed launch, then set final canonical/sitemap.

Set server environment variable `FLUTTER_WEB_URL` to the isolated Flutter
deployment URL before building to activate the Web button. An absent value
shows an honest setup status instead of a simulated QR login.

Flutter is hosted on a separate preview origin. Its build script is
`scripts/build-web-preview.sh`, from the repository root, with output
`build/web`. It needs public `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` for
an isolated test project. Never use the production project for this preview.
Set the device-login Edge Function's allowed origin to that Flutter origin.
The mobile testing build must use the same test project's public values.
No production customer data is copied. Relational sync and admin writes stay off.

APK and Windows links are intentionally unavailable until signed artifacts
are published. Do not point preview links at debug-signed production releases.
