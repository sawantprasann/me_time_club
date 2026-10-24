# Fixes applied — 24 October 2026

## Expired sessions redirect to login

- Authenticated API requests now detect HTTP 401 responses and notify the app that the session has expired.
- The app clears the saved session and cached daily pages, then opens the login screen.
- Saved profiles with a missing or blank token also open login.
- Expired sessions no longer produce an offline fallback daily page.
- Late responses for an old token cannot sign out a newer session. Concurrent expiry responses are handled safely.
- Network failures and other server errors keep the user signed in. Invalid login credentials remain a login-form error.

Changed files:

- `lib/main.dart`
- `lib/services/api_service.dart`
- `lib/screens/tabs/home_tab.dart`
- `test/session_expiry_test.dart`

## Login button loading text

- The login button now displays **“Signing in…”** while the request is pending.
- The shared CTA button accepts a custom loading label. Its existing default remains available for daily-page generation.

Changed files:

- `lib/screens/auth/login_screen.dart`
- `lib/widgets/shared_widgets.dart`

## Consistent logo and app icons

- Added the supplied chamomile logo as the shared brand artwork.
- Applied it to welcome, login, registration, app headers in both themes, session loading, and the transition screen.
- Generated Android launcher and adaptive icons and all iOS app icon sizes from the same artwork.
- Updated native Android and iOS launch screens and removed the previous logo assets.

## Calendar month and year dropdowns

- Replaced the year chip grid with a dropdown beside the month name.
- Refined the layout: month, year, and subtle navigation arrows now sit inside the calendar card. The compact year menu opens below its control, uses the app's palette, and marks the selected year with a check.
- Selecting a year keeps the displayed month, resets the selected day to the first, and reloads that month's data.
- The dropdown uses the active day/night theme and includes the displayed year when month navigation moves outside the usual year range.
- Verified in the iOS simulator: choosing 2025 displayed October 2025 and requested data for `2025-10`. Code analysis passed.
- Verified the refined menu opens below the header and selecting 2026 returns to October 2026.
- Added a month dropdown matching the year selector, including the same colors, rounded styling, check mark, and menu placement.
- Moved the Tasks, Page, and Cycle legend into the calendar card beneath a divider.
- The calendar displays only the week rows needed for the selected month, keeping the legend close to the dates.
- Verified month selection in the iOS simulator using February 2026; code analysis passed.
- Expanded the year dropdown back to 2000, while retaining the current year and six future years.
- Date dropdowns now automatically scroll to the selected value when opened, so the year menu does not start at 2000 each time.

## Emotional Alignment card

- Pulled the latest `main` changes (`8dba4dc`) before updating the UI and resolved overlaps while preserving the earlier local fixes.
- Matched the supplied reference with an uppercase section heading, an italic introduction, and separate Feeling, Need, and Response panels.
- Added soft rose accents for Feeling and Need, a gold accent for Response, rounded outlines, subtle gradients, and a stronger left accent on each panel.
- Kept the page's actual content and support for the day/night palette and wrapping text.
- All nine existing tests passed after the merge, and Flutter code analysis passed.
- Loaded the merged app in the iOS simulator and visually verified the updated card with the saved daily page, including its long response text.

## Chamomile welcome card

- Added a welcome card above the daily page's opening thought, matching the supplied layout.
- The card uses the shared logo, an uppercase Chamomile heading, and a warm italic greeting personalized with the user's first name and time of day.
- The greeting supports the day/night palette and wraps within the card.

## Insight, Micro Ritual, and Gentle Reads

- Updated Today's Insight with a gold outline star, uppercase heading, and readable sans-serif body text to match the reference.
- Updated Micro Ritual with a soft gold background, outlined sun icon, and italic serif text.
- Rebuilt Gentle Reads as a post-style card with a brand header, optional square image, optional caption, and optional clickable link.
- Moved Gentle Reads directly above Fun Moment, after Micro Ritual, on the daily page. It remains available on Home before a daily page is opened.
- Matched the Gentle Reads heading to the other card headings using uppercase text and the shared section-label font, weight, letter spacing, and muted color.
- Image, text, and link work independently in every combination, including an empty content item. No minimum length or new content-length limits were introduced because maximum values have not been supplied.
- Long captions expand with Read more; previous/next navigation remains available.
- Added optional API fields `image_url`, `image_alt`, `link_url`, and `link_label`, with support for `text`, `image`, and `link` aliases. Existing title/body responses continue to work.
- Link taps open the device's browser. Images have loading and unavailable states.
- Flutter code analysis passed and all 27 tests passed, including the 18 new Gentle Reads model and widget checks.
- Rebuilt and launched the app on the iPhone 15 Pro simulator; visually checked Today's Insight, Micro Ritual, and the text-only Gentle Reads post with its expandable caption.
- Added `url_launcher` for external links. The installed Flutter SDK also updated iOS plugin integration to Swift Package Manager and the UIScene app lifecycle during the successful rebuild.

## Circle menu and post cards

- Replaced the Circle navigation icon with the reference's outer circle, central ring, and four inward marks; it updates color with the selected tab and theme.
- Updated feed cards with Anonymous labels, compact timestamps, italic post text, rounded outlines, and Respond with feeling / Respond controls.
- Added independent inline feeling/reply panels, seven preset feelings, a draft field, disabled/working/error send states, and response display when provided by the feed.
- Drafts survive closing and switching panels. The layout adapts to narrow screens and enlarged text in both themes.
- Removed the temporary availability message. Respond with feeling now shows only the seven feeling options; the input and Send button appear only under Respond. Feeling selection preserves any separate written draft.
- Selecting a feeling now adds an `Anonymous: <feeling>` line below that post, matching the design. Multiple distinct feelings remain visible after closing the panel; selecting the same feeling again does not duplicate it. These UI-preview responses remain local to the card until backend integration is available and reset on app restart/feed reload.
- Selecting a feeling automatically closes the feeling options and restores the Respond with feeling button, while keeping the Anonymous response visible below the post.
- Prepared a shareable backend handoff in `docs/CIRCLE_API.md` and an importable `docs/CIRCLE_OPENAPI.json` specification. These cover feed responses, preset/written creation, anonymous author fields, duplicate-preset behavior, errors, validation, and acceptance checks. The response API remains proposed until the backend is implemented.
- Removed the Heart, Hug, and Leaf controls and their obsolete screen state. The feeling panel now contains only the seven preset responses from the design.
- The new written/feeling reply API is not yet provided. Per the user's instruction, built the UI first and documented the proposed requests and responses in `docs/CIRCLE_API.md`. Send remains disabled in the app until the backend is ready; drafts are not presented as saved replies.
- Code analysis passed. All 35 tests passed: the 27 existing tests and eight Circle tests covering panel switching, retained drafts, pending/failed submissions, request payloads, anonymous reply labels, and narrow screens with enlarged text. The Circle checks also verify that exactly seven feeling chips are shown and Heart, Hug, and Leaf controls are absent.
- Restarted the app in the iPhone 15 Pro simulator and visually verified the updated Circle menu icon, feed cards, and expanded feeling panel.

## Verification

- Flutter code analysis passed after the logo changes.
- All nine tests passed after the logo changes, including the welcome-screen smoke test and eight regression tests covering expiry, signing in again, missing tokens, network/server errors, stale responses, concurrent failures, and invalid credentials.
- The expired saved session redirected to the login screen on the iPhone 15 Pro simulator.
- The iOS app rebuilt successfully and was reinstalled on the iPhone 15 Pro simulator with the new logo, app icon, and launch screen.
- Validated all 25 iOS icon entries, 10 Android launcher icons, and native XML resources. The iOS marketing icon is 1024 × 1024 with no alpha channel.
- Android icon assets were generated and checked; an Android app build was not run.
