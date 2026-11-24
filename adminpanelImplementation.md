# Admin Panel: Implementation Plan

Status (2026-11-24): Phases 1 and 2 are built, plus the DSS part of Phase 3, on branch `feature/admin-portal` in the backend repo (not committed). Not built yet: Phase 0 (admin sidebar shell, staff authenticator-app 2FA), the socialprotection.gov.bd gap finder, announcements, CSV export. **SMS is not planned**, so admin-issued reset codes and in-app notifications are the permanent design, not a stopgap.

Built, and how it differs from the plan below:
- **Users:** paginated and filtered list (role, status, app/website, district, activity, language, civic role); a person's page with activity counts (never message text), devices and admin history; reveal phone, reset code, unlock, sign out everywhere, suspend/reactivate (each with a reason in the audit log); role change; delete (super admin, typed name). Delete reuses the platform's existing account deletion (data removed, audit kept) instead of a separate soft delete.
- **New services:** paste-a-link, the DSS discovery job, review screen beside the source text, approve / approve as draft / reject / snooze / duplicate, "changed facts" candidates for programmes already listed, and notifying matching citizens (max one new-programme notice per person per day).
- **Found on the live DSS site** and handled: an incomplete TLS certificate chain (fixed by bundling Sectigo's public intermediate; verification stays on); page bodies shipped base64-encoded in `<rt-renderer>`; generic page titles ("পাতা"); and the same Bangla letter য় stored two ways, which broke title matching.

Originally written against the code as of 2026-11-23.

The admin panel has two jobs:

1. **Users.** See and control every user of the mobile app and the website.
2. **New government services.** When a government site offers a service the platform does not list, show it to an admin. If the admin approves it, it appears in the user app and the website.

---

## 1. What already exists (so we don't rebuild it)

The backend repo (`ShebarJanala`, Next.js 15, Drizzle, libSQL/Turso, deployed to Cloudflare or Vercel) already has a staff portal at `/[locale]/(app)/admin`. The Flutter app and the website both read the same `/api/v1` API and the same database, so **one admin panel on the backend controls both.** Nothing in the Flutter app is needed to build the panel.

| Area | Exists today | Where |
|---|---|---|
| Staff roles | `moderator` < `administrator` < `super_admin`, plus separate civic roles and donor org link | `lib/domain/enums.ts`, `lib/http/session.ts` |
| Guards | `requireStaff`, `canManageUsers`, `canApproveChanges`, and a middleware check on `/admin` | `lib/http/session.ts`, `middleware.ts` |
| Users | List (latest 100, name or phone search), change role, civic role, donor org, suspend. Cannot promote to or above own rank, cannot edit self, sessions are revoked on demotion or suspension | `api/v1/admin/users`, `components/admin/UserTable.tsx` |
| Programmes | List, create (always `draft` + `unverified_sample`), edit, archive. Verifying needs `administrator` and cannot be combined with an edit. Editing a verified programme drops it back to `pending_review` | `api/v1/admin/programs`, `programs/[id]` |
| Review queue | `knowledge_reviews` with `proposedPatch`, applied only on approval by an administrator | `api/v1/admin/moderation` |
| Audit | Append-only, hash-chained `audit_log` with `recordAudit()` and `verifyAuditChain()` | `modules/admin/admin.service.ts` |
| Operations | Analytics, system health, job runner, AI logs, SMS outbox, ledger integrity, organisations, rules | `api/v1/admin/*`, `components/admin/*` |
| Citizen visibility | Citizens only ever see `status IN ('open','rolling')` | `modules/opportunities/opportunity.service.ts`, `modules/knowledge/retrieval.ts` |

The last row matters: **a programme becomes visible to users by its `status`**, and creation already starts at `draft`. The approval step in section 5 reuses that, so an unapproved service cannot leak to users.

### Gaps this plan closes

1. **Users:** no pagination (hard limit 100), no filters beyond a text search, no user detail page, no unlock / force-logout / PIN-reset / delete, no per-user activity, no export, no way to message users, and nothing records which client (app or web) a user uses.
2. **New services:** nothing discovers services on government sites. Every programme today comes from the seed files or is typed in by hand.
3. **Admin security:** staff sign in with the same 4-6 digit PIN as citizens. That is too weak for an account that can edit everyone's data.
4. **Admin UX:** the admin section is a horizontal tab strip inside the citizen layout. It is fine for a few screens and not for a full console.

---

## 2. Decisions

| Decision | Choice | Why |
|---|---|---|
| Where it lives | Extend the existing Next.js admin in the backend repo. No separate app | Same auth, same DB, same deploy, same audit chain. A separate app means a second login system and a second place to secure |
| Layout | New `(admin)` route group with its own desktop-first shell (sidebar + top bar), moved out of the citizen `(app)` layout | The citizen layout is built for phones; an admin console needs tables and a persistent sidebar |
| Mobile admin | Not in scope. Admin panel is web only | One interface to secure and test |
| Discovery output | A staging table, **never** the live `opportunities` table | Candidates cannot reach citizens by accident, whatever a query forgets to filter |
| AI role | Drafts fields and highlights the source text. A human approves | The product's rule is deterministic eligibility and verified sources; AI text must never go live on its own |
| Eligibility rules | Written by a human after approval, not by the crawler | A wrong rule tells a citizen they do or don't qualify. A published programme without rules already shows "unknown", which is safe |
| Crawl scope | Allow-listed official domains only, polite fetching, manual "submit a link" as the first version | Government sites are inconsistent and sometimes unreachable from foreign edge servers; manual submission works on day one |
| Approval | **One administrator is enough** (decided) | No second-approver workflow to build. The audit log and one-click archive are the safety net |
| Eligibility rules | **Publishing does not require rules** (decided) | The programme shows with eligibility "unknown" until rules are added; the dashboard's existing "missing rules" count is the to-do list |
| Notifying users | **Matching users are notified on publish** (decided), with a per-approval switch to turn it off | Uses the existing eligibility engine to pick users; the admin sees the audience count before confirming |
| Staff second factor | **Authenticator app (TOTP) with one-time recovery codes** (decided: SMS is not available) | Works offline from SMS; see section 6 |

---

## 3. Roles and permissions

Reuse the existing ranks. Add one helper per capability in `lib/http/session.ts` instead of comparing ranks inline.

| Capability | moderator | administrator | super_admin |
|---|:-:|:-:|:-:|
| View dashboards, users (masked phone), candidates, audit | yes | yes | yes |
| Reveal full phone number (logged) | no | yes | yes |
| Suspend / reactivate, force logout, unlock | no | yes | yes |
| Reset a user's PIN (issues a one-time reset code, never sets or shows a PIN; see 4.2) | no | yes | yes |
| Change role (below own rank), civic role, donor org | no | yes | yes |
| Delete / anonymise a user | no | no | yes |
| Export users (CSV) | no | no | yes |
| Edit a candidate draft, reject, snooze | yes | yes | yes |
| **Approve and publish a candidate** | no | yes | yes |
| Manage sources (add / enable / delete) | no | yes | yes |
| Send an announcement to a user segment | no | yes | yes |
| Read a user's chat messages (break-glass, reason required, logged) | no | no | yes |

Rules that stay as they are today: nobody changes their own role or status, nobody grants a role at or above their own, and a demotion or suspension revokes sessions immediately.

---

## 4. Part A: User management

### 4.1 Screens

- **Users list** (`/admin/users`): server-side pagination, sortable columns, filters (role, status, civic role, district, language, platform, last active, joined between), text search on name / phone. Columns: name, masked phone, role, status, district, platform, last active, joined. Row click opens the detail page. Bulk select for suspend / reactivate / force logout / send message.
- **User detail** (`/admin/users/[id]`):
  - Profile and account (role, civic role, donor org, language, district, phone verified, locked until, failed PIN attempts).
  - Devices and sessions (client, last seen, revoke one or all).
  - Activity **counts and timeline only**: saved programmes, plans, tasks done, conversations, issues reported, feedback given. Message text is not shown by default.
  - Admin history: every audit entry about this user.
  - Action panel (permissions per section 3), each action asks for a reason.
- **Segments and announcements** (`/admin/announcements`): choose a segment (district, language, role, saved a given programme) and send an **in-app notification** through the existing notifications module. Preview the audience count first. The `channel` field is kept so SMS can be switched on later without redesign; until then SMS is not offered.
- **Dashboard additions:** daily active users, new users, app vs web split, from `analytics_daily`.

### 4.2 API (all under `/api/v1/admin`, all `requireStaff`, all audited)

| Method | Path | Purpose |
|---|---|---|
| GET | `/users` | Extend: `page`, `pageSize`, `sort`, filters. Response keeps `items` and adds `meta.total` |
| GET | `/users/[id]` | Detail with counts, sessions, recent audit |
| PATCH | `/users/[id]` | Existing role / status / civic changes, plus `reason` and optional `suspendedUntil` |
| POST | `/users/[id]/force-logout` | Calls the existing `logoutEverywhere` |
| POST | `/users/[id]/unlock` | Clears `lockedUntil` and `failedPinAttempts` |
| POST | `/users/[id]/reset-pin` | **No SMS is available**, so a code cannot be texted. The admin gets a one-time reset code (valid 15 minutes, single use, stored hashed) to read to the person after checking who they are (phone call back or in person). The person enters it on the existing forgot-PIN screen and chooses a new PIN. The admin never sees or sets a PIN. Needs a reason; audited |
| POST | `/users/[id]/reveal-phone` | Returns the full number and writes an audit entry |
| DELETE | `/users/[id]` | Soft delete: `status='deleted'`, personal fields anonymised, sessions revoked. Reuses the retention logic in `retention.service.ts` |
| POST | `/users/export` | CSV, `super_admin` only, audited with the filter used |
| POST | `/announcements` | Create and send to a segment; returns audience size |

The existing `PATCH /users` stays working for the current UI; it is retired once the detail page ships.

### 4.3 Data changes

- `sessions.client` (`'web' | 'mobile'`) and `sessions.lastSeenAt`, filled in at sign-in and renew. First check whether the table already has them. This is what makes "app vs web" real.
- `users.suspendedUntil` and `users.suspensionReason` (nullable).
- `announcements` table (id, authorId, segment JSON, channel, body bn/en, audienceCount, sentAt).

### 4.4 Privacy rules

- Phone numbers are masked in lists (`017****678`); revealing one is an audited action.
- Admins do not read conversations by default. The break-glass view requires a typed reason and is limited to `super_admin`.
- Exports and bulk actions record the filter and the count, not just "export happened".
- A deleted user keeps an anonymised row so foreign keys and audit entries stay valid.

---

## 5. Part B: New government services (discover → review → approve → live)

### 5.1 Flow

```
 Government site / page
        │  (1) discover
        ▼
 service_sources ──fetch──► source_snapshots (hash + text, change detection)
        │  (2) extract (rules first, AI draft second)
        ▼
 service_candidates   status = pending        ◄── never visible to users
        │  (3) admin reviews: side-by-side draft vs source text, edits
        ├── reject / snooze / mark duplicate
        ▼  (4) approve   (administrator or above)
 opportunities row created from the frozen draft
        │     status 'open', verified by the approving admin, audited, indexed
        ▼
 Mobile app + website read it from /api/v1/opportunities
        (5) matching users are notified (optional)
```

### 5.2 Tables (new, in `lib/db/schema.ts`)

- `service_sources`: id, name, organizationId, baseUrl, `kind` (`sitemap | rss | html_list | single_page | manual`), `allowedHostPattern`, `adapterConfig` JSON (selectors / list URL), `intervalHours`, `enabled`, `lastRunAt`, `lastStatus`, `lastError`.
- `source_snapshots`: id, sourceId, url, `contentHash`, `textExcerpt`, `httpStatus`, `fetchedAt`. A changed hash on a known URL is a change signal.
- `service_candidates`:
  - `id`, `sourceId`, `sourceUrl`, `discoveredAt`
  - `kind` (`new | change`), `targetOpportunityId` (set for `change`)
  - `status` (`pending | approved | rejected | snoozed | duplicate`)
  - `draft` JSON, shaped like `upsertOpportunitySchema` (titles, summaries, description, benefits, application steps, deadline, categories, districts, URLs)
  - `evidence` JSON: for each field, the source sentence it came from
  - `confidence`, `extractor` (`rules | ai | manual`), `contentHash`, `duplicateOfId`
  - `reviewerId`, `decidedAt`, `decisionNote`, `publishedOpportunityId`

Changes to an existing programme (a new deadline, a new amount) go through the same table with `kind='change'`. Approving one applies the patch with the same code path as the existing moderation `PATCH`.

### 5.3 Discovery and extraction

1. **Manual submit (build first).** Admin pastes an official URL; the server fetches it, extracts, and creates a candidate. This works with any site and needs no per-site adapter.
2. **Watched sources.** An admin registers a source (a ministry's service list or notices page). A scheduled job fetches it, compares hashes, and sends only new or changed pages to extraction.
3. **Extraction order.**
   1. Deterministic parsing (title, dates, amounts, links, headings).
   2. AI model through the existing `modules/ai` providers, with a fixed JSON schema validated by `zod`. Output is a draft only. Any field it cannot support from the page is left blank, not guessed.
   3. Each filled field stores its source sentence in `evidence` so the reviewer can check it.
4. **Duplicate detection** before a candidate is shown: same `sourceUrl`, same `contentHash`, or title similarity to an existing programme (reuse the tokenizer in `modules/knowledge`). Likely duplicates are labelled, not silently dropped.
5. **Safety rules for the fetcher:** allow-listed hosts only (HTTPS), obey `robots.txt`, identify the client, 1 request per second per host, response size cap, timeout, no following redirects off the allow-list, strip scripts, never store personal data from a page.

Jobs are added to the existing `JOBS` registry and `job_runs` log (`discover_sources`, `extract_candidates`), triggered by a cron call to the existing jobs endpoint using a secret. Work is done in small batches, because Cloudflare Workers and Vercel functions have short time and subrequest limits; a single request must not try to crawl everything.

### 5.4 The review screen (`/admin/candidates`)

- **Inbox:** tabs (New services, Changes, Snoozed, Rejected, Published), badge count, source, discovered date, confidence, duplicate warning.
- **Detail:** left, the draft as an editable form (English and Bangla side by side); right, the source page text with each field's evidence highlighted and a link to the original. A checklist blocks approval until required fields are present: organisation, category, bilingual title and summary, at least one application step, an official URL on an allowed host.
- **Actions:** Edit, Approve & publish, Approve as draft (creates the programme as `draft` for later), Reject (reason required), Snooze, Mark duplicate (pick the existing programme).
- **After approval:** a banner offers "Add eligibility rules" (links to `/admin/rules`) and shows the programme in the "missing rules" count that the dashboard already tracks.

### 5.5 Approval semantics

- Only `administrator` or above can approve. Moderators can edit, reject and snooze.
- Approve is one transaction: insert the `opportunities` row from the **frozen draft** (so what was reviewed is exactly what goes live), set `verificationStatus='verified'`, `verifiedBy` and `lastVerifiedAt`, set `status='open'` (or `draft` for "approve as draft"), index it for search, link `publishedOpportunityId`, and write an audit entry.
- This stays consistent with the current rule "you can't verify and edit in the same action": the editing happened on the candidate beforehand; the publish step changes nothing about the content.
- Candidates cannot be published twice (unique `publishedOpportunityId`, and a status check inside the transaction).
- A programme can be pulled back at any time: archive it (existing `DELETE`), which sets `status='archived'`.

### 5.6 How it reaches the app and website

- **Website and app list:** both read `/api/v1/opportunities`, so the new programme shows up on the next load of the Programmes tab or Home strips. With the Flutter cache added in the last change, a stored list is shown first and refreshed in the background, so a new service appears within one refresh (pull-to-refresh is immediate).
- **Notify matching users (on by default):** after approval, the existing eligibility engine finds users whose profile matches the programme and an in-app notification is created through `notifications`. The approve dialog shows the audience count and a switch to turn it off. Only users with a "likely eligible" or "partially eligible" verdict are notified, never "unknown", so nobody is told about something they have no reason to expect. A programme with no rules yet notifies nobody until rules exist. Notification is in-app only for now (no SMS).

### 5.7 Which government sources to start with

I tested the candidate sites on 2026-11-23 with a few read-only requests (home page, `robots.txt`, sitemap / feed, and the structure of the DSS pages). Findings, not guesses, are marked as tested; the rest is stated as unverified.

| Tier | Source | What I found | Role in the pipeline |
|---|---|---|---|
| **1: start here** | **dss.gov.bd** (Dept. of Social Services) | Reachable. No `robots.txt` (404), so no stated restrictions. No sitemap or RSS feed, but it has `/pages/notices`, `/pages/service-boxes`, `/pages/notification-circulars` and an HTML sitemap at `/views/sitemap`. Programme pages are server-rendered Bangla text with eligibility, amounts and a "last updated" stamp. The old-age allowance page returned 700 Tk/month, age 65 (men) / 62 (women), income under 45,000 Tk, and disqualifiers, which is exactly what a draft needs. It is also already the source for 7 of our 42 seeded programmes | Primary watched source. Use the page's "last updated" stamp plus a content hash to detect changes. Best place to find new allowances and application windows |
| **1** | **socialprotection.gov.bd** (national social protection programme site) | Reachable. WordPress with a permissive `robots.txt` (only `/wp-admin/` blocked) and a `wp-sitemap.xml`, the easiest site to crawl politely. Its own text says the system has about 115 safety-net programmes across 39 ministries (I read this in a search summary, not on the page itself) | **Gap finder, not a content source.** Compare its programme list with our 42 and create "stub" candidates (name, ministry, link) for programmes we lack. An admin then follows the link to the implementing ministry for details. Its documents are policy-level, so they do not carry application steps |
| **2: add once the pipeline works** | **Ministry and agency sites on the same portal platform:** dwa.gov.bd, nsda.gov.bd, dyd.gov.bd, shed.gov.bd, moedu.gov.bd, mopa.gov.bd, cabinet.gov.bd | All reachable, all 404 on `robots.txt` (no stated restrictions), and several resolve to the same address as dss.gov.bd, which suggests a shared platform. **Unverified:** I only inspected the DSS page structure, so one adapter may or may not fit the others | Try the DSS adapter on each; keep the ones that parse cleanly, leave the rest manual |
| **2** | **bangladesh.gov.bd** (national portal) and **www.mygov.bd** | bangladesh.gov.bd is reachable and has an "all e-services in Bangladesh" directory page. `mygov.bd` redirects and answers at `https://www.mygov.bd`. **Unverified:** I did not confirm that either lists services in crawlable HTML rather than through scripts | Discovery of online services across agencies. Check the page structure before building an adapter; manual submit until then |
| **2** | **dae.gov.bd, bmet.gov.bd, ddm.gov.bd** | Reachable, no `robots.txt`, but hosted on a different address block, so probably a different template | Manual submit first; check structure later |
| **3: manual only** | **dghs.gov.bd** (Directorate General of Health Services) | Its `robots.txt` is Cloudflare-managed and carries content signals `search=yes, ai-train=no, use=reference`, and it blocks several AI crawlers by name, including ClaudeBot | Our fetcher is a different client, but the site's stated intent is no AI use of its content. So: **no AI extraction for this source.** An admin submits the link and types the fields by hand |
| **Not sources** | Other sites that rank high in searches: third-party blogs and aggregators (for example teachers.gov.bd blog posts, bdservicerules.info), news sites, NGO sites such as BRAC and BLAST, and district DSS sites (`dss.<district>.gov.bd`) | The aggregators quote allowance figures and application dates but are secondary and undated in places. District sites mostly republish PDF notices | Never auto-ingested. The host allow-list is `.gov.bd` plus the specific seeded domains (for example `bb.org.bd`). NGO programmes stay manual |

**Recommendation:** build Phase 2 around **dss.gov.bd** (new allowances, application windows, amount changes) and use **socialprotection.gov.bd** to find programmes we are missing. That pair covers the highest-value benefits for citizens (old-age, widow, disability, and other allowances) and gives one polite, well-structured source and one permissive catalogue. Treat every other site as "try the DSS adapter, otherwise manual".

Additional rules this research adds to the fetcher:

- **Honour content signals.** If a site's `robots.txt` carries `ai-train=no` or `ai-input=no` (or blocks AI crawlers by name), the source is flagged **no-AI** automatically: pages can still be fetched for change detection and shown to the admin, but extraction is rule-based or manual only.
- **Test from the production region.** My checks ran from a developer machine. The deployment (Vercel region `pdx1`, or Cloudflare's edge) is in the US, and some Bangladeshi sites may be slow or blocked from there. Phase 2 starts with a reachability report from the real deployment; if a source fails, fall back to manual submit for it.
- **One source = one adapter config.** The DSS adapter reads `/pages/notices` and `/pages/static-pages/*`; others are added only when their structure is confirmed.

---

## 6. Admin security

1. **Second factor for staff, without SMS.** Staff sign-in requires the PIN **and** a 6-digit code from an authenticator app (TOTP, RFC 6238). Enrolment shows a QR code once; 8 single-use recovery codes are shown once and stored hashed. The TOTP secret is stored encrypted with the existing `field-encryption` helper. A `super_admin` can reset another staff member's second factor (audited). Staff sessions are shorter (for example 30 minutes idle) and are marked in the token. New table: `staff_mfa` (userId, encryptedSecret, enrolledAt, lastUsedStep, recoveryCodeHashes).
2. **Step-up confirmation** for destructive actions (delete, export, role change, publish): re-enter PIN or a fresh code.
3. **Rate limits** on all `/admin` routes using the existing `rate-limit` helper, tighter than citizen routes.
4. **Optional IP allow-list** for `super_admin` actions, set in env.
5. **Every mutation calls `recordAudit`** with before/after, actor, IP and user agent. Add a **read-only audit viewer** with filters (actor, action, entity, date) and a "verify chain" button using the existing `verifyAuditChain()`.
6. **Defence in depth:** middleware check, layout check, and a role check in each route handler (the current pattern), plus tests that fail if an admin route lacks a guard.
7. **CSRF and CORS:** admin mutations are same-origin only; the mobile bearer-token path is not accepted on `/admin` routes.

---

## 7. Build phases

Sizes are rough: S = a day or two, M = about a week, L = two weeks or more.

| Phase | Deliverable | Size |
|---|---|---|
| **0. Foundation** | `(admin)` route group + sidebar shell, permission helpers, staff authenticator-app 2FA (no SMS) and short sessions, audit viewer, route-guard test | M |
| **1. Users** | Paginated filtered list, user detail page, force-logout / unlock / reset-PIN / reveal-phone, `sessions.client`, `suspendedUntil`, soft delete | M |
| **2. Review pipeline (manual)** | Reachability check from the deployed region, tables, "submit a link" fetch + extraction (DSS adapter first), candidates inbox and review screen, approve / reject / snooze / duplicate, publish transaction, tests | L |
| **3. Watched sources** | Source registry UI, scheduled discovery of dss.gov.bd, socialprotection.gov.bd gap finder, change detection and `kind='change'` candidates, fetcher safety rules (incl. no-AI flag) | L |
| **4. Reach users** | Notify matching users, announcements and segments, app-side cache eviction (section 8), dashboard additions | M |
| **5. Hardening** | Load and permission tests, monitoring on job failures, runbook, export, break-glass chat view | M |

Phases 0 and 1 are independent of 2 and 3 and can be built in parallel. Phase 2 is the smallest version of the "approve a new service" feature and is useful before any crawler exists.

---

## 8. Changes needed in the Flutter app

Small, and only because of the new caching:

1. **Evict stale copies on removal.** If the server answers `NOT_FOUND` for a programme page (an admin archived it), delete its cached copy instead of continuing to show it. Today `cachedFirst` swallows every error and keeps the cached page; it should treat `NOT_FOUND` differently from "offline". Same for saved items that point at an archived programme.
2. **Deep link from a notification** to the new programme (optional, with section 5.6).
3. No admin UI in the app.

---

## 9. Testing

Backend uses Vitest, and the repo already has `tests/` suites to follow.

- **Permissions:** table-driven test across every admin route and every role; each route must return 403 below its required rank. A test that enumerates `api/v1/admin/**/route.ts` and fails when one lacks a guard.
- **Users:** pagination and filter correctness, cannot self-edit, cannot grant at-or-above own rank, demotion revokes sessions, masked phone in lists, reveal writes an audit row, export is `super_admin` only, deleted user is anonymised.
- **Candidates:** a pending candidate never appears in any citizen endpoint (`/opportunities`, search, chat retrieval, map, notifications); approve creates exactly one programme and is idempotent under a double click; approve by a moderator is refused; published content equals the reviewed draft; a duplicate is flagged.
- **Fetcher:** blocks non-allow-listed hosts and redirects off them, respects `robots.txt`, size and time caps, survives malformed HTML.
- **Extraction:** AI output that fails schema validation produces a manual-entry candidate, never a crash and never a half-filled published record.
- **Audit:** every mutation adds a chained entry; `verifyAuditChain()` still passes after a full scenario.

---

## 10. Risks and open questions

| Risk | Plan |
|---|---|
| Bangladeshi government sites are inconsistent, change layout, and may block or time out requests from foreign edge servers (tested only from a developer machine, not the deployment region) | Manual submit first; per-source adapters only for sites that prove stable; show source health in the UI; consider running the fetcher from a regional host if blocking is confirmed |
| AI extraction gets a rule, amount, or deadline wrong | Human review is mandatory; evidence highlighted per field; AI is never allowed to write eligibility rules or verify anything |
| A bad approval reaches every user | Archive is one click and audited; candidate drafts are frozen so a review can be re-read; publishing needs `administrator` |
| Crawling legal or etiquette problems | Public official pages only, `robots.txt`, rate limit, identified client, source URL stored and shown to users |
| Admin account takeover | 2FA, step-up for destructive actions, short sessions, rate limits, audit chain |
| Edge runtime limits on long jobs | Small batches triggered by cron; every job writes to `job_runs` |

**Decided with you:** one administrator is enough to approve; publishing does not require eligibility rules; matching users are notified (switchable per approval); staff second factor is an authenticator app because SMS is not available.

**Still open:**

1. **Production reachability.** Can the deployed server reach dss.gov.bd and socialprotection.gov.bd reliably? Phase 2 begins by checking this from the real deployment.
2. **When will SMS become available?** Until then, user PIN resets are admin-issued codes and announcements are in-app only (sections 4.2 and 4.1). If an SMS gateway is planned, tell me, so the `channel` fields are wired for it.
3. **Who are the first staff accounts**, and do we need a separate tier for district-level admins? Today there is one global `administrator` level.
4. **Notification volume.** Should there be a daily cap per user for "new service" notifications, to avoid flooding people when several services are approved at once? (Suggested: at most 1 per day, the rest batched.)
