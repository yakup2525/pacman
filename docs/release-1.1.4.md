# Ghost Runner 1.1.4 (15)

Baseline: Play production 1.1.2 (13); 1.1.3 (14) was already under production review and available in internal testing when inspected. Build 15 is the next unused code.

## Ads and privacy

Android only. Google Mobile Ads Flutter 9.2.0 resolves Mobile Ads 25.5.0 and UMP 4.0.0. No Firebase analytics/crash SDK, account service, gameplay backend, banners, rewarded ads, or mediation adapters. Marionette initializes in debug only.

A neutral local age-band screen precedes advertising. Unknown age and Under 16: no UMP request, Mobile Ads initialization or ad requests. Ages 16–17: teen treatment and non-personalized ad requests. All ads: G maximum content rating. Android app measurement initialization is delayed until SDK initialization.

Only post-run Restart can show an interstitial: at least 120 seconds cumulative active play, three completed runs each lasting at least 15 active seconds, 180-second cooldown, two impressions per rolling hour (persisted locally), three per process session. A five-minute post-reward suppression exists as a defensive guard; there is no reward feature. Pauses/background time do not accrue gameplay grace. No launch/resume fullscreen ad. Fullscreen requests are single-flight; failures allow restart. Consent gates every preload/show. Debug/profile use Google's official test unit; release has the Ghost Runner production unit.

Policy: https://wolftrailstudio.com/privacy/ghost-runner/
SDK disclosure basis: https://developers.google.com/admob/android/privacy/play-data-disclosure

Final disclosure categories: approximate location (IP-derived), app interactions, crash logs, diagnostics and device/other identifiers; Google collection/sharing for advertising/marketing, analytics and fraud/security. Limited/non-personalized ads can still process data, so declining personalization is not a blanket opt-out of collection. Local age band, cached update floor and impression timestamps are not uploaded by app code. HTTPS update requests expose ordinary network metadata to Cloudflare. Email support is external to the app. No precise location/contacts/media permission, login or cloud save.

## Minimum-version operations

Introduced in **1.1.4 (15)**. The HTTPS policy at `https://wolftrailstudio.com/updates/ghost-runner.json` is package-specific and initially sets `minimumVersionCode: 15`. Build numbers are compared numerically; below the minimum blocks play and Android back; equal/above are allowed. The only store destination is `https://play.google.com/store/apps/details?id=com.wolftrail.ghost_runner`.

For a future **1.1.5 (16)** or higher, first make the new build available to every affected user/country/device/track, then raise the website minimum to 16 and deploy. Never raise the floor to a build unavailable to affected users. Check again/resume re-fetches the rule; already verified minima survive offline. A first offline launch without a cached rule is allowed; an unavailable policy cannot reliably impose an unknown minimum. Store/network failure cannot crash or dismiss an already-known mandatory state. The website can lower a floor to recover from a mistaken rule once reachable.

Historical builds 14 and earlier lack this infrastructure and cannot be forced by this code. Future enforcement is available to users already on build 15 or later after they fetch the policy; it is not a retroactive guarantee for every installed app.

## Release boundary

AAB: `build/app/outputs/bundle/release/app-release.aab`. Release signing uses ignored existing local credentials. Do not commit signing files or credentials. Keep the final Play release in testing/draft until owner production approval. Runtime native UMP decisions and fullscreen ad callbacks require completion before declaring release-ready; do not equate form-load logs or pacing unit tests with those runtime checks.
