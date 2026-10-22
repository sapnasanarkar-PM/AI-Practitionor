# actiontrack: Claude Code conversation

Messages in order. Text in *[square brackets]* says what Claude did with tools between replies. The output of each step follows it in a code block. Long paths into the session's folder are shortened to relative paths. Source code Claude wrote is not repeated, because it's in the project files.

---

## 1. User

I'm a Project Manager (not a full-time developer) building a small CLI tool
called "actiontrack" as a task from my mentor. I have about one hour, so I
want a working, simple solution.

Goal: read markdown meeting notes from a folder, track action items, and draft
follow-up emails in Gmail (never send).

Commands:
1. actiontrack ingest <folder> - parse every .md note (date, attendees, free
   text; action items look like "- [ ] Priya to send the revised quote by
   Friday"). Store owner, task, due date (resolved to a real date, relative to
   the meeting date), source file and status.
2. actiontrack list - filters: --owner, --status open|done|overdue,
   --due-before <date>. Overdue items must be clearly highlighted.
3. actiontrack done <id> - mark an item done.
4. actiontrack followup <owner> - one email per owner covering open and
   overdue items, created as a Gmail DRAFT via the Gmail MCP connector.
   It must never send.

Edge cases: duplicate items across meetings, items with no owner or no date,
two people with the same first name, malformed notes (skip and report, never
crash).

The sample notes are in ./notes (30+ files, some messy or malformed).

Please do NOT write code yet. First: (1) read a few of the notes and tell me
what formats you see, (2) list any doubts or assumptions, (3) propose a plan
and file structure. Explain things in simple terms.

## 1. Claude

*[Searched this session's folder and the "AI Practitonor" folder for notes: none found. Opened a folder picker, which was cancelled.]*

```
Glob notes/**/*  (session folder)                         -> No files found
Glob **/notes/*.md  (C:\Users\...\Documents\AI Practitonor) -> No files found
Glob **/*.md        (C:\Users\...\Documents\AI Practitonor) -> No files found
Folder picker -> Directory selection was cancelled by the user.
```

I couldn't read your notes yet. This session started without a project folder, so there's no `./notes` here. I also checked your "AI Practitonor" folder and found no `.md` files. The folder picker was cancelled, so I haven't guessed at what the notes look like.

What I can give you now is my doubts and a draft plan based on your brief. Once I've seen real notes I'll update both.

### 1. Formats in the notes
**Not done yet. I need the folder first.** When I read them I'll look for:
- How the date is written (a `Date:` line, the file name, or the title)
- How attendees are listed (a comma list, bullet points, full names or first names only)
- How action items are written. Your example is `- [ ] Priya to send … by Friday`. I'll also check for ticked `[x]` items, `TODO:` lines, or items with no checkbox
- What "messy" and "malformed" mean here: a missing date, broken checkboxes, an empty file, odd encoding

### 2. Doubts and assumptions (please confirm or correct)
1. **Meeting date:** if a note has no date I can find, I'll skip it and report it as malformed, because without a date we can't work out due dates.
2. **Relative dates:** "by Friday" means the *next* Friday after the meeting. If the meeting was itself on a Friday, it means the following week's Friday. "Tomorrow", "next week" and "end of month" work the same way.
3. **No owner:** the item is still saved with owner "unassigned" and is never emailed.
4. **No due date:** the item is still saved but can't be overdue. It shows as "no date".
5. **Duplicates:** two items count as the same if the owner matches and the task text matches after ignoring case, punctuation and extra spaces. I'll keep one copy and remember every note it appeared in.
6. **Two people with the same first name:** I'll use the attendee list to match "Priya" to a full name. If two Priyas attended the same meeting, the item is marked "ambiguous owner" so you can fix it by hand. I won't guess.
7. **Email addresses:** the notes probably don't contain them. I'd keep a small `people.json` file that maps names to emails, which you fill in. With no email listed, `followup` still creates the draft with an empty "To" field.
8. **Re-running ingest:** running it again on the same folder won't create duplicates, and items you marked done stay done.
9. **"Today"** means the computer's current date. That's what decides whether an item is overdue.
10. **Gmail:** the CLI tool can't use the Gmail connector directly, because only I (Claude) can. So `followup` would write the email text, and then I'd create the Gmail draft through the connector for you. The only Gmail action I'd use is "create draft", never "send".

### 3. Plan (simple version)
**Language:** Python, with no extra libraries to install. **Storage:** one JSON file, which is easy to open and inspect.

```
actiontrack/
  actiontrack.py     ← the command you run (ingest / list / done / followup)
  parser.py          ← reads one note: date, attendees, action items
  dates.py           ← turns "by Friday" into a real date
  store.py           ← saves/loads items in actiontrack.json, handles duplicates
  people.json        ← names → email addresses (you fill in)
  actiontrack.json   ← created automatically; the list of items
  tests/             ← a few quick checks using sample notes
```

**Build order, about one hour total:**
1. **Parser and dates (~20 min):** get one clean note working, then the messy ones. A bad file is skipped and reported, never a crash.
2. **Store and `ingest` (~10 min):** save items with an ID, owner, task, due date, source file and status, and handle duplicates.
3. **`list` and `done` (~10 min):** add the filters. Overdue items show in **red** with an "OVERDUE" label.
4. **`followup` (~10 min):** one email per owner listing open and overdue items, then a Gmail draft, never sent.
5. **Test on all 30+ notes (~10 min):** check the skipped-files report makes sense.

---

## 2. User

@"C:\Users\sapna.sanarkar_codit\Downloads\notes (2).zip"
here is the note fpor your reference

## 2. Claude

*[Unzipped the archive into a new folder (36 files) and read every note.]*

Unzip and list (file, size in bytes):

```
notes_src\notes\2026-09-01-quote-portal-kickoff.md      575
notes_src\notes\2026-09-02-standup.md                   290
notes_src\notes\2026-09-03-billing-migration-sync.md    544
notes_src\notes\2026-09-08-quote-portal-weekly.md       464
notes_src\notes\2026-09-09-notes-final-v2.md            0
notes_src\notes\2026-09-09-qa-standup.md                336
notes_src\notes\2026-09-10-acme-renewal-prep.md         487
notes_src\notes\2026-09-14-onboarding-flow-design.md    521
notes_src\notes\2026-09-15-quote-portal-weekly.md       439
notes_src\notes\2026-09-16-standup.md                   318
notes_src\notes\2026-09-17-billing-migration-sync.md    479
notes_src\notes\2026-09-18-design-review.md             942
notes_src\notes\2026-09-19-offsite-draft.txt            71
notes_src\notes\2026-09-21-incident-review.md           767
notes_src\notes\2026-09-22-quote-portal-weekly.md       444
notes_src\notes\2026-09-23-standup.md                   271
notes_src\notes\2026-09-24-onboarding-flow-design.md    491
notes_src\notes\2026-09-25-qa-sync.md                   314
notes_src\notes\2026-09-28-acme-renewal-checkin.md      490
notes_src\notes\2026-09-29-billing-cutover-planning.md  552
notes_src\notes\2026-09-30-q4-offsite.md                1685
notes_src\notes\2026-09-30-standup.md                   314
notes_src\notes\2026-10-01-quote-portal-weekly.md       442
notes_src\notes\2026-10-02-finance-sync.md              455
notes_src\notes\2026-10-03-sales-pipeline.md            185
notes_src\notes\2026-10-05-onboarding-retro.md          457
notes_src\notes\2026-10-06-quote-portal-weekly.md       450
notes_src\notes\2026-10-07-standup.md                   265
notes_src\notes\2026-10-08-billing-go-no-go.md          478
notes_src\notes\2026-10-09-security-review.md           1076
notes_src\notes\2026-10-10-sales-weekly.md              337
notes_src\notes\2026-10-12-billing-post-cutover.md      488
notes_src\notes\2026-10-13-quote-portal-weekly.md       432
notes_src\notes\2026-10-14-acme-renewal-wrapup.md       477
notes_src\notes\scratch.md                              249
notes_src\notes\untitled.md                             105
```

Contents of every note:

````
===== 2026-09-01-quote-portal-kickoff.md =====
# Meeting: Quote portal kickoff
Date: 2026-09-01
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor

## Discussion
We agreed to rebuild the quote portal in phases, starting with the customer-facing quote view. Acme is waiting on a revised quote and is our reference customer for the pilot. Cloud spend for staging still needs sign-off.

## Action items
- [ ] Priya to send the revised quote to Acme by Friday
- [ ] Rahul to set up the staging environment by 2026-09-08
- [ ] Anita to share first wireframes by Thursday
- [ ] Sam to confirm cloud budget with finance

===== 2026-09-02-standup.md =====
# Meeting: Team standup
Date: 2026-09-02
Attendees: Rahul Mehta, Sam Okafor, Anita Desai

## Discussion
Quick round. Rahul is blocked on repo access. Sam has a VPN guide half written.

## Action items
- [ ] Rahul to open the repo access request by tomorrow
- [ ] Sam to share the VPN guide

===== 2026-09-03-billing-migration-sync.md =====
# Meeting: Billing migration sync
Date: 2026-09-03
Attendees: Karan Joshi, Sam Okafor, Rahul Verma, Priya Shah

## Discussion
The invoice schema maps cleanly except for rounding on multi-currency invoices. Priya raised that rounding is the main test risk. Cutover date is not fixed yet.

## Action items
- [ ] Karan to export last quarter invoices by 10 Sep
- [ ] Rahul to review the schema mapping doc by Monday
- [ ] Priya to draft the test plan for invoice rounding by end of next week
- [ ] Sam to snapshot the production DB before cutover

===== 2026-09-08-quote-portal-weekly.md =====
# Meeting: Quote portal weekly
Date: 2026-09-08
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer

## Discussion
Login screen is in progress. Meera will help get a procurement contact at Acme. Staging environment is now up.

## Action items
- [ ] Priya N. to send revised quote to Acme — by Friday
- [ ] Rahul to finish login screen by Wed
- [ ] Meera to ask Acme for their procurement contact
- [x] Rahul to set up the staging environment

===== 2026-09-09-notes-final-v2.md =====
===== 2026-09-09-qa-standup.md =====
# Meeting: QA and billing standup
Date: 9 September 2026
Attendees: Rahul Verma, Priya Shah, Karan Joshi

## Discussion
Test data for billing is the blocker. Karan will send the vendor list so Priya can build realistic fixtures.

## Action items
- [ ] Karan to send the vendor invoice list by Friday
- [ ] Priya to set up the test data

===== 2026-09-10-acme-renewal-prep.md =====
# Meeting: Acme renewal prep
Date: 2026-09-10
Attendees: Meera Iyer, Lena Fischer, Priya Nair, Karan Joshi

## Discussion
Acme renews in November. We need usage numbers, a discount ceiling and a call with their CTO before we send pricing.

## Action items
- [ ] Lena to pull Acme's usage report for the last 6 months by tomorrow
- [ ] Karan to confirm discount ceiling with the CFO by 2026-09-14
- [ ] Meera to book the renewal call with Acme's CTO
- [ ] Someone to update the CRM notes

===== 2026-09-14-onboarding-flow-design.md =====
# Meeting: Onboarding flow design
Date: Monday, 14 September 2026
Attendees: Anita Desai, Priya Shah, Rahul Verma, Lena Fischer

## Discussion
Walked through the five-step signup. SSO is the biggest unknown. Lena wants real customer quotes on the landing page.

## Action items
- [ ] Anita to finalise the welcome-email copy by Wed 16 Sep
- [ ] Priya to write acceptance tests for the signup flow by 18 Sep
- [ ] Rahul to estimate the SSO work
- [ ] Lena to collect 5 customer quotes for the landing page by end of month

===== 2026-09-15-quote-portal-weekly.md =====
# Meeting: Quote portal weekly
Date: 2026-09-15
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer

## Discussion
Revised quote went out to Acme. Pagination on the quote list is broken for more than 50 rows.

## Action items
- [x] Priya to send the revised quote to Acme
- [ ] Anita to share updated wireframes by Thursday
- [ ] Sam to confirm cloud budget with finance by Friday
- [ ] Rahul to fix the pagination bug

===== 2026-09-16-standup.md =====
---
title: Team standup
date: 2026-09-16
attendees: [Anita Desai, Lena Fischer, Meera Iyer]
---

## Discussion
Case study draft is next. Pipeline sheet needs an update before the sales review.

## Action items
- [ ] Lena to draft the case study outline by 2026-09-21
- [ ] Meera to update the pipeline sheet by Friday

===== 2026-09-17-billing-migration-sync.md =====
# Meeting: Billing migration sync
Date: 2026-09-17
Attendees: Karan Joshi, Sam Okafor, Rahul Verma, Priya Shah, Priya Nair

## Discussion
Dry run on staging is the next gate. Cutover checklist needs a sign-off owner. Schema review is still outstanding.

## Action items
- [ ] Priya to sign off the cutover checklist by Monday
- [ ] Sam to run the dry-run migration on staging by 2026-09-22
- [x] Karan to export last quarter invoices
- [ ] Rahul to review the schema mapping doc

===== 2026-09-18-design-review.md =====
# Meeting: Design review (brain dump)
Date: 2026-09-18
Attendees: Anita Desai, Rahul Mehta, Priya Nair, Lena Fischer

## Discussion
Lots of ideas, not much structure. The dashboard feels crowded and the contrast on the grey cards is poor. Rahul and Anita disagreed about whether components should take a `variant` prop or separate classes; they will settle it between them.

Lena thinks we should test the prototype with five real users before polishing anything. Priya offered to help recruit. Nobody has written the design-system changelog since August. Everybody should look at the prototype before next time.

## Action items
- [ ] @anita: audit colour contrast on the dashboard by Mon
- [ ] Anita & Rahul to agree on the component API by Wednesday
- [ ] Lena (with Priya) to collect user feedback on the prototype by 2026-09-25
- [ ] Everyone to review the prototype before the next review
- [ ] TBD to write the design-system changelog

===== 2026-09-19-offsite-draft.txt =====
Draft agenda for the offsite. Not a meeting note.
- [ ] Book the venue

===== 2026-09-21-incident-review.md =====
# Meeting: Incident review: billing double-charge
Date: 2026-09-21
Attendees: Sam Okafor, Rahul Verma, Priya Shah, Karan Joshi

## Discussion
Forty-one customers were charged twice on 19 September because the payment call was retried without an idempotency key. Support forwarded this note from the customer success lead:

> Please make sure someone owns refunds this time.
> - [ ] Karan to refund affected customers by Friday

The quoted line above is customer success's wish, not an agreed action. The real actions are below.

## Action items
- [ ] Sam to write the postmortem by EOD tomorrow
- [ ] Rahul to add idempotency keys to the payment call by Friday
- [ ] Priya to add a regression test for double charge by 25 Sep
- [ ] Karan to refund affected customers

===== 2026-09-22-quote-portal-weekly.md =====
# Meeting: Quote portal weekly
Date: 2026-09-22
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer

## Discussion
Wireframes slipped a week. Budget is confirmed. Pagination fix is next for Rahul.

## Action items
- [ ] Anita to share updated wireframes by Thursday
- [x] Sam to confirm cloud budget with finance
- [ ] Meera to send Acme the procurement form by 2026-09-25
- [ ] Rahul to fix the pagination bug by Wednesday

===== 2026-09-23-standup.md =====
# Meeting: Team standup
Date: 2026-09-23

## Discussion
Short one. Rahul's branch is behind main; Sam will rotate the staging credentials after the weekend.

## Action items
- [ ] Rahul to rebase the feature branch by Thursday
- [ ] Sam to rotate the staging credentials

===== 2026-09-24-onboarding-flow-design.md =====
# Meeting: Onboarding flow design
Date: 2026-09-24
Attendees: Anita Desai, Priya Shah, Rahul Verma, Lena Fischer

## Discussion
Welcome copy is nearly there. Signup tests are done. Customer quotes are late because two customers have not replied.

## Action items
- [ ] Anita to finalise the welcome-email copy by Friday
- [x] Priya to write acceptance tests for the signup flow
- [ ] Lena to collect 5 customer quotes for the landing page by 2 Oct
- [ ] Rahul to estimate SSO work by Monday

===== 2026-09-25-qa-sync.md =====
# Meeting: QA sync
Date: 2026-09-25
Attendees: Priya Shah, Rahul Verma

## Discussion
Bug list has grown to 37 items. Three are critical: pagination, rounding and a login redirect loop.

## Action items
- [ ] Priya to triage the open bug list by Monday
- [ ] Rahul to fix the top three critical bugs by 2026-10-02

===== 2026-09-28-acme-renewal-checkin.md =====
# Meeting: Acme renewal check-in
Date: 2026-09-28
Attendees: Meera Iyer, Lena Fischer, Karan Joshi, Priya Nair

## Discussion
CTO call is still not booked. Pricing sheet is the next deliverable. A one-pager would help the internal review.

## Action items
- [ ] Meera to book the renewal call with Acme's CTO by Wednesday
- [ ] Karan to send Acme the revised pricing sheet by 2026-10-01
- [ ] Lena to share the usage report with Meera
- [ ] Priya to prepare the renewal one-pager by Friday

===== 2026-09-29-billing-cutover-planning.md =====
# Meeting: Billing migration cutover planning
Date: 2026-09-29
Attendees: Karan Joshi, Sam Okafor, Rahul Verma, Priya Shah, Priya Nair

## Discussion
Cutover is planned for the weekend of 10 October. Customers must be told about a maintenance window and invoice edits must be frozen the day before.

## Action items
- [ ] Priya S. to run the invoice rounding tests by Thursday
- [ ] Priya N. to notify customers about the maintenance window by 2026-10-05
- [ ] Sam to schedule cutover for Saturday 10 Oct
- [ ] Karan to freeze invoice edits from 9 Oct

===== 2026-09-30-q4-offsite.md =====
# Meeting: Q4 planning offsite
Date: 2026-09-30
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer, Karan Joshi, Lena Fischer, Priya Shah, Rahul Verma

## Morning: where we are
We started with a look at Q3. Quote portal is on track for a beta in October. Billing migration is the riskiest piece because the cutover touches every paying customer; Karan reminded everyone that finance closes the books on the 15th. Onboarding is slower than planned mostly because SSO keeps growing. There was a long tangent about whether to hire two QA engineers or contract them; no decision, but someone has to own the plan.

Meera walked through the pipeline. Orbit Labs is the biggest new opportunity, Acme the biggest renewal. She needs final Q4 targets before she can brief her team.
- [ ] Meera to finalise the Q4 sales targets by Oct 3rd
  - [ ] Karan to validate targets against the budget by Oct 5th
* [ ] Lena to run the customer survey, results due 15 October
+ [ ] Sam to propose the on-call rotation by mid-October

## Afternoon: people and process
Hiring: both Priyas were in the room when this came up and both nodded. Architecture: Rahul said an overview doc would stop the repeated questions in standups; it is unclear which Rahul meant.
- [ ] Priya to own the hiring plan for the two QA roles
- [ ] Rahul to prepare the architecture overview by Friday
- [ ] Everyone to submit their Q4 goals by 7 Oct

| Owner | Action | Due |
|-------|--------|-----|
| Anita | Refresh the brand kit | 2026-10-09 |

ACTION: Karan to circulate the offsite summary tomorrow

## Parking lot
Office move, the Friday demo slot, and whether we still need the old wiki. Nothing agreed.

===== 2026-09-30-standup.md =====
---
title: Team standup
date: 2026-09-30
attendees: [Priya Nair, Sam Okafor, Karan Joshi]
---

## Discussion
Q4 cloud spend needs approval. Roadmap draft is due before the end of the week.

## Action items
- [ ] Karan to approve the Q4 cloud spend by 2026-10-02
- [ ] Priya to share the Q4 roadmap draft by Friday

===== 2026-10-01-quote-portal-weekly.md =====
# Meeting: Quote portal weekly
Date: 2026-10-01
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer

## Discussion
Beta build is green. Designs are almost final. The team still has not picked a launch date.

## Action items
- [x] Meera to send Acme the procurement form
- [ ] Rahul to deploy the beta to staging by Friday
- [ ] Anita to hand over final designs to dev by 2026-10-06
- [ ] Team to decide on the launch date

===== 2026-10-02-finance-sync.md =====
# Meeting: Finance sync
Date: 2026-10-02
Attendees: Karan Joshi, Sam Okafor, Meera Iyer

## Discussion
Cloud spend approved with a cap. Sam to propose a 10% cost cut. Board slide is due after the cutover.

## Action items
- [X] Karan to approve the Q4 cloud spend
* [ ] Sam to cut cloud costs by 10% — proposal by 2026-10-09
+ [ ] Meera to share the Q4 pipeline forecast by Wednesday
- [ ] Karan to prepare the board finance slide by 12 Oct

===== 2026-10-03-sales-pipeline.md =====
# Meeting: Sales pipeline
Date: sometime last week
Attendees: Meera Iyer, Lena Fischer

## Action items
- [ ] Meera to chase Orbit Labs by Friday
- [ ] Lena to clean up duplicate leads

===== 2026-10-05-onboarding-retro.md =====
# Meeting: Onboarding flow checkpoint
Date: 2026-10-05
Attendees: Anita Desai, Priya Shah, Lena Fischer, Rahul Verma

## Discussion
Welcome copy is final. Customer quotes arrived. SSO spike is the last open piece and needs a start date.

## Action items
- [ ] Rahul to start SSO spike by next Tuesday
- [ ] Lena to publish the customer quotes by 9 Oct
- [x] Anita to finalise the welcome-email copy
- [ ] Priya to review the welcome email for accessibility

===== 2026-10-06-quote-portal-weekly.md =====
# Meeting: Quote portal weekly
Date: 2026-10-06
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer

## Discussion
Beta deploy slipped. Meera has a demo booked with Acme. We need monitoring before real traffic.

## Action items
- [ ] Rahul to deploy the beta to staging by tomorrow
- [ ] Meera to demo the portal to Acme on 2026-10-14
- [ ] Sam to set up uptime monitoring
- [ ] Priya to write the beta test checklist by Thursday

===== 2026-10-07-standup.md =====
# Meeting: Team standup
Date: 2026-10-07
Attendees: Rahul Mehta, Rahul Verma, Anita Desai

## Discussion
Anita has a PR open for the style guide and wants a review.

## Action items
- [ ] Rahul to review Anita's PR by tomorrow
- [ ] Anita to update the style guide

===== 2026-10-08-billing-go-no-go.md =====
# Meeting: Billing migration go/no-go
Date: 2026-10-08
Attendees: Karan Joshi, Sam Okafor, Rahul Verma, Priya Shah, Priya Nair

## Discussion
All gating tests pass. Rollback plan needs to be written down before we say go. Customers have been told.

## Action items
- [ ] Priya to circulate the go/no-go summary by EOD
- [ ] Sam to confirm rollback plan by 2026-10-09
- [ ] Karan to freeze invoice edits from 9 Oct
- [x] Priya N. to notify customers about the maintenance window

===== 2026-10-09-security-review.md =====
# Meeting: Security review
Date: 2026-10-09
Attendees: Sam Okafor, Rahul Verma, Priya Shah, Karan Joshi

## Discussion
The external pen-test report landed on Monday. Findings were mostly low severity but two need action this month: admin accounts without MFA and an outdated express dependency with a known advisory. Sam pasted the auditor's suggested format into the doc, which is why some lines below look like tasks but are not ours:

```
# example from the auditor's template
- [ ] Owner to remediate finding by <date>
```

<!-- - [ ] Sam to buy hardware tokens for everyone by Friday  (cut from the agenda, not agreed) -->

Karan confirmed the two ex-contractors no longer have access. The incident response document is still a stub. Everyone agreed the pen-test findings should not be shared outside this group.

## Action items
- [ ] Sam to enable MFA on all admin accounts by 2026-10-16
- [ ] Rahul to patch the outdated express dependency by Monday
- [ ] Priya to document the incident response steps by 23 Oct
- [x] Karan to revoke access for the two ex-contractors

===== 2026-10-10-sales-weekly.md =====
# Meeting: Sales weekly
Date: 2026-10-10
Attendees: Meera Iyer, Lena Fischer

## Discussion
Orbit Labs wants a proposal. Three new leads came in through the webinar.

## Action items
- [ ] Meera to send the proposal to Orbit Labs by Tuesday
- [ ] Lena to log the three new leads in CRM by EOD
- [x] Lena to update the Acme account notes

===== 2026-10-12-billing-post-cutover.md =====
# Meeting: Billing migration post-cutover
Date: 2026-10-12
Attendees: Karan Joshi, Sam Okafor, Rahul Verma, Priya Shah

## Discussion
Cutover finished on Saturday with one hiccup in invoice numbering. Old DB stays read-only for three weeks.

## Action items
- [ ] Sam to decommission the old billing DB by 2026-10-30
- [ ] Priya to verify invoice totals for the first 50 invoices by Wednesday
- [ ] Karan to reconcile September ledger by 15 Oct
- [ ] Rahul to write the migration runbook

===== 2026-10-13-quote-portal-weekly.md =====
# Meeting: Quote portal weekly
Date: 2026-10-13
Attendees: Priya Nair, Rahul Mehta, Anita Desai, Sam Okafor, Meera Iyer

## Discussion
Beta is on staging. Demo is tomorrow. A few spacing issues came up in review.

## Action items
- [x] Rahul to deploy the beta to staging
- [ ] Anita to fix spacing issues flagged in review by Friday
- [ ] Priya to collect beta feedback from Acme by 2026-10-20
- [ ] Meera to follow up on the demo

===== 2026-10-14-acme-renewal-wrapup.md =====
# Meeting: Acme renewal wrap-up
Date: 2026-10-14
Attendees: Meera Iyer, Lena Fischer, Karan Joshi, Priya Nair

## Discussion
CTO call is booked. Contract goes to legal tomorrow. One-pager is still outstanding. QBR planned for November.

## Action items
- [ ] Karan to send the final contract to legal by tomorrow
- [ ] Lena to schedule the quarterly business review for November
- [x] Meera to book the renewal call with Acme's CTO
- [ ] Priya to prepare the renewal one-pager

===== scratch.md =====
 ��# Meeting  Date: �(
�PNG
[remaining content is binary data that can't be shown as text]
===== untitled.md =====
- [ ] Sam to chase the vendor
- [ ] Priya to send the slides by Friday

no header, no date, no attendees
````

I unzipped the notes and read all 36 files, not just a few. They're short, and the tricky cases are spread across many of them. Today is 22 Oct 2026, so many items will already be overdue.

### 1. What formats I found

**The normal note** (about 25 files) looks like this:
```
# Meeting: Quote portal weekly
Date: 2026-09-08
Attendees: Priya Nair, Rahul Mehta, ...
## Discussion ...
## Action items
- [ ] Rahul to finish login screen by Wed
- [x] Rahul to set up the staging environment     ← already done
```

**Variations the tool has to handle:**

| What varies | Examples |
|---|---|
| Header style | 2 standups use a different header block (`---` / `date:` / `attendees: [...]`) |
| Date style | `2026-09-08`, `9 September 2026`, `Monday, 14 September 2026` |
| Checkbox style | `- [ ]`, `* [ ]`, `+ [ ]`, `[x]` and `[X]`, one indented sub-item |
| Other ways to write an action | a table row (Owner / Action / Due) and an `ACTION: Karan to…` line, both in the offsite note |
| How the owner is written | `Priya N.`, `@anita`, `Anita & Rahul`, `Lena (with Priya)`, `Everyone`, `Team`, `Someone`, `TBD` |
| How the due date is written | by Friday / Wed / Mon / tomorrow / EOD, `by 10 Sep`, `by Oct 3rd`, `by 2026-10-02`, `end of next week`, `end of month`, `mid-October`, `next Tuesday`, `results due 15 October`, `on 2026-10-14`, `from 9 Oct`, `for November` |

**Traps: lines that look like tasks but aren't:**
- **Incident review (21 Sep):** a quoted line, `> - [ ] Karan to refund… by Friday`. The note itself says it isn't an agreed action.
- **Security review (9 Oct):** a template line inside a code block, and a task hidden in an HTML comment marked "not agreed".
- **"Sam to cut cloud costs by 10% — proposal by 2026-10-09":** "by 10%" is not a date.

**Broken files that should be skipped and reported:**
- `2026-09-09-notes-final-v2.md`: empty
- `scratch.md`: binary junk, not text
- `untitled.md`: no header, no date, no attendees
- `2026-10-03-sales-pipeline.md`: the date says "sometime last week"
- `2026-09-23-standup.md`: has a date but no attendee list
- `2026-09-19-offsite-draft.txt`: not a `.md` file, so ignore it

**Same first names:** there are two Priyas (Nair and Shah) and two Rahuls (Mehta and Verma). The attendee list usually settles it. For example, the Rahul in the quote-portal meetings is always Mehta. But in 4 notes both people with that name attended, so it's genuinely unclear who "Priya" or "Rahul" means.

**Repeats across meetings:** the same task comes back week after week, often with new wording or a new due date. For example, "Anita to share updated wireframes by Thursday" appears on 1, 15 and 22 Sep. Later meetings also tick off earlier items with `[x]`.

### 2. Doubts, with my suggested answers

1. **Can a later tick close an earlier item?** If 15 Sep says `[x] Priya to send the revised quote`, I'd mark the 1 Sep item done. **Suggest: yes.**
2. **Repeated item with a new due date:** keep one item, use the **latest** due date, and remember every note it came from.
3. **Matching repeats:** treat two items as the same if the owner is the same and the task text matches after ignoring case, "the", punctuation and the due-date part.
4. **Unclear owner** (both Priyas were in the meeting): don't guess. Save it as "Priya (ambiguous)", show it in `list`, and leave it out of emails with a warning. You can fix it by hand.
5. **Group owners:**
   - `Anita & Rahul` becomes one item for each person
   - `Lena (with Priya)` goes to Lena
   - `Everyone`, `Team`, `Someone`, `TBD` become "unassigned", shown in `list` but never emailed
6. **Actions outside the "Action items" heading:** count checkbox lines anywhere, plus the table row and `ACTION:` lines. Ignore quotes, code blocks and HTML comments.
7. **Vague dates:**
   - `EOD` means the meeting day
   - `end of next week` means Friday of the following week
   - `end of month` means the last day of that month
   - `mid-October` means 15 Oct
   - `for November` means 30 Nov
   - `from 9 Oct` means 9 Oct
   - If I can't read the date at all, the item has no due date
8. **"Sometime last week" as the meeting date:** the file name has the date (2026-10-03). **Suggest:** use the file-name date with a warning, and skip the file only if there's no usable date anywhere (as with `untitled.md`).
9. **Missing attendees (23 Sep):** still read the items. Just don't use the attendee list to work out who a first name means.
10. **Email addresses** aren't in the notes. I'd add a small `people.json` (name → email) for you to fill in.
11. **Gmail:** I don't see a Gmail connector in this session yet, so you'll need to connect it before step 4. The tool writes each draft's text, then I create it in Gmail with "create draft" only, never "send".

### 3. Plan and file structure

This uses plain Python with nothing extra to install, and saves everything in one JSON file.

```
actiontrack/
  actiontrack.py   ← the commands: ingest / list / done / followup
  parser.py        ← reads one note → date, attendees, action items
  dates.py         ← turns "by Friday" into a real date
  owners.py        ← "Priya N." / "@anita" → full name, or flags it ambiguous
  store.py         ← saves items, merges repeats, applies later [x] ticks
  people.json      ← names → emails (you fill in)
  data.json        ← created automatically
  tests/           ← quick checks for the tricky cases above
```

**Order of work, about one hour:**
1. **Parser and dates (~20 min):** clean notes first, then the variations and traps.
2. **Owners, store and `ingest` (~15 min):** ends with a "skipped files" report.
3. **`list` and `done` (~10 min):** add the filters. Overdue items show in red with "OVERDUE".
4. **`followup` (~10 min):** one draft per owner covering open and overdue items.
5. **Test run on all 36 files (~5 min).**

The notes are now in a `notes_src/notes` folder inside the folder the app made for this session.

If you want to keep this work, I can move this session to a folder you choose.

---

## 3. User

Your suggested answers are approved, with these changes:

1. A later [x] tick closes an earlier item only when owner and task both
   match. A manual `done <id>` always wins and can never be reopened by a
   later meeting.
2. Overdue is computed at run time (due date < today), never stored. Add a
   --today flag (or ACTIONTRACK_TODAY env var) so tests are deterministic.
3. `followup` never sends. It writes each owner's draft (to, subject, body)
   to ./drafts/ and supports --dry-run. The Gmail draft is then created via
   the Gmail MCP "create draft" tool only.
4. Commit people.example.json only. Add people.json, data.json and drafts/
   to .gitignore.
5. README.md must include a section listing every assumption (date
   resolution, owner matching, duplicates, skipped files).

## 3. Claude

*[Moved the notes to `./notes`. Found that Python, Node and Git are not installed, and asked which way to go.]*

```
> python --version; Move-Item notes_src\notes notes; Remove-Item notes_src; (Get-ChildItem notes).Count
Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
36

> (look for py, python3, node, dotnet, pwsh, git)
py =>
python3 => C:\Users\sapna.sanarkar_codit\AppData\Local\Microsoft\WindowsApps\python3.exe
node =>
dotnet =>
pwsh =>
git =>

> python3 --version; (look for winget)
Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.
winget => C:\Users\sapna.sanarkar_codit\AppData\Local\Microsoft\WindowsApps\winget.exe
```

**Question asked:** Python isn't installed on this computer (and neither are Node or Git). How should I build actiontrack?
- Install Python (Recommended)
- Use PowerShell instead

**User's answer:** Use PowerShell instead

*[Checked the PowerShell version and script policy, then wrote `lib/Dates.ps1`, `lib/Owners.ps1`, `lib/Parser.ps1` and `lib/Store.ps1`.]*

```
> $PSVersionTable.PSVersion; Get-ExecutionPolicy -List
5.1.26100.9444

        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process          Bypass
  CurrentUser       Undefined
 LocalMachine       Undefined
```

Dates, owner matching, the note parser and storage are written; now writing the four commands.

*[Wrote `lib/Commands.ps1`, `actiontrack.ps1` and `actiontrack.cmd`. Ran `ingest notes` and `list`, and checked dates and owners against the notes.]*

```
> $env:ACTIONTRACK_TODAY='2026-10-22'; .\actiontrack.cmd ingest notes
Read 32 notes from notes.
Items: 95 new, 23 updated, 0 unchanged. Total stored: 95.

Skipped 3 file(s) that could not be read:
  - 2026-09-09-notes-final-v2.md: file is empty
  - scratch.md: file contains binary data
  - untitled.md: no meeting date found, and the file name has no date

Ignored 1 file(s) that are not .md: 2026-09-19-offsite-draft.txt

Warnings:
  - 2026-09-23-standup.md: no attendee list; first names matched against everyone in the other notes
  - 2026-10-03-sales-pipeline.md: meeting date 'sometime last week' not understood; used the date in the file name (2026-10-03)

11 item(s) have no clear owner and are never emailed:
  - Priya (ambiguous): circulate the go/no-go summary  (2026-10-08-billing-go-no-go.md)
  - Priya (ambiguous): own the hiring plan for the two QA roles  (2026-09-30-q4-offsite.md)
  - Priya (ambiguous): sign off the cutover checklist  (2026-09-17-billing-migration-sync.md)
  - Rahul (ambiguous): prepare the architecture overview  (2026-09-30-q4-offsite.md)
  - Rahul (ambiguous): rebase the feature branch  (2026-09-23-standup.md)
  - Rahul (ambiguous): review Anita's PR  (2026-10-07-standup.md)
  - unassigned: decide on the launch date  (2026-10-01-quote-portal-weekly.md)
  - unassigned: review the prototype before the next review  (2026-09-18-design-review.md)
  - unassigned: submit their Q4 goals  (2026-09-30-q4-offsite.md)
  - unassigned: update the CRM notes  (2026-09-10-acme-renewal-prep.md)
  - unassigned: write the design-system changelog  (2026-09-18-design-review.md)
exit=0

> .\actiontrack.cmd list
  ID  STATUS    DUE         OWNER               TASK  [latest note]
   3  OVERDUE   2026-09-03  Anita Desai         share first wireframes  [2026-09-01-quote-portal-kickoff.md]
   5  OVERDUE   2026-09-03  Rahul Mehta         open the repo access request  [2026-09-02-standup.md]
   8  OVERDUE   2026-09-07  Rahul Verma         review the schema mapping doc  [2026-09-17-billing-migration-sync.md +1 more]
   2  done      2026-09-08  Rahul Mehta         set up the staging environment  [2026-09-08-quote-portal-weekly.md +1 more]
  11  OVERDUE   2026-09-09  Rahul Mehta         finish login screen  [2026-09-08-quote-portal-weekly.md]
   7  done      2026-09-10  Karan Joshi         export last quarter invoices  [2026-09-17-billing-migration-sync.md +1 more]
   1  done      2026-09-11  Priya Nair          send the revised quote to Acme  [2026-09-15-quote-portal-weekly.md +2 more]
   9  OVERDUE   2026-09-11  Priya Shah          draft the test plan for invoice rounding  [2026-09-03-billing-migration-sync.md]
  13  OVERDUE   2026-09-11  Karan Joshi         send the vendor invoice list  [2026-09-09-qa-standup.md]
  15  OVERDUE   2026-09-11  Lena Fischer        pull Acme's usage report for the last 6 months  [2026-09-10-acme-renewal-prep.md]
  16  OVERDUE   2026-09-14  Karan Joshi         confirm discount ceiling with the CFO  [2026-09-10-acme-renewal-prep.md]
   4  done      2026-09-18  Sam Okafor          confirm cloud budget with finance  [2026-09-22-quote-portal-weekly.md +2 more]
  20  done      2026-09-18  Priya Shah          write acceptance tests for the signup flow  [2026-09-24-onboarding-flow-design.md +1 more]
  26  OVERDUE   2026-09-18  Meera Iyer          update the pipeline sheet  [2026-09-16-standup.md]
  25  OVERDUE   2026-09-21  Lena Fischer        draft the case study outline  [2026-09-16-standup.md]
  27  OVERDUE   2026-09-21  Priya (ambiguous)   sign off the cutover checklist  [2026-09-17-billing-migration-sync.md]
  29  OVERDUE   2026-09-21  Anita Desai         audit colour contrast on the dashboard  [2026-09-18-design-review.md]
  28  OVERDUE   2026-09-22  Sam Okafor          run the dry-run migration on staging  [2026-09-17-billing-migration-sync.md]
  35  OVERDUE   2026-09-22  Sam Okafor          write the postmortem  [2026-09-21-incident-review.md]
  24  OVERDUE   2026-09-23  Rahul Mehta         fix the pagination bug  [2026-09-22-quote-portal-weekly.md +1 more]
  30  OVERDUE   2026-09-23  Anita Desai         agree on the component API  [2026-09-18-design-review.md]
  31  OVERDUE   2026-09-23  Rahul Mehta         agree on the component API  [2026-09-18-design-review.md]
  23  OVERDUE   2026-09-24  Anita Desai         share updated wireframes  [2026-09-22-quote-portal-weekly.md +1 more]
  40  OVERDUE   2026-09-24  Rahul (ambiguous)   rebase the feature branch  [2026-09-23-standup.md]
  19  done      2026-09-25  Anita Desai         finalise the welcome-email copy  [2026-10-05-onboarding-retro.md +2 more]
  32  OVERDUE   2026-09-25  Lena Fischer        collect user feedback on the prototype  [2026-09-18-design-review.md]
  36  OVERDUE   2026-09-25  Rahul Verma         add idempotency keys to the payment call  [2026-09-21-incident-review.md]
  37  OVERDUE   2026-09-25  Priya Shah          add a regression test for double charge  [2026-09-21-incident-review.md]
  39  done      2026-09-25  Meera Iyer          send Acme the procurement form  [2026-10-01-quote-portal-weekly.md +1 more]
  21  OVERDUE   2026-09-28  Rahul Verma         estimate SSO work  [2026-09-24-onboarding-flow-design.md +1 more]
  42  OVERDUE   2026-09-28  Priya Shah          triage the open bug list  [2026-09-25-qa-sync.md]
  17  done      2026-09-30  Meera Iyer          book the renewal call with Acme's CTO  [2026-10-14-acme-renewal-wrapup.md +2 more]
  44  OVERDUE   2026-10-01  Karan Joshi         send Acme the revised pricing sheet  [2026-09-28-acme-renewal-checkin.md]
  47  OVERDUE   2026-10-01  Priya Shah          run the invoice rounding tests  [2026-09-29-billing-cutover-planning.md]
  59  OVERDUE   2026-10-01  Karan Joshi         circulate the offsite summary  [2026-09-30-q4-offsite.md]
  22  OVERDUE   2026-10-02  Lena Fischer        collect 5 customer quotes for the landing page  [2026-09-24-onboarding-flow-design.md +1 more]
  43  OVERDUE   2026-10-02  Rahul Verma         fix the top three critical bugs  [2026-09-25-qa-sync.md]
  46  OVERDUE   2026-10-02  Priya Nair          prepare the renewal one-pager  [2026-10-14-acme-renewal-wrapup.md +1 more]
  56  OVERDUE   2026-10-02  Rahul (ambiguous)   prepare the architecture overview  [2026-09-30-q4-offsite.md]
  60  done      2026-10-02  Karan Joshi         approve the Q4 cloud spend  [2026-10-02-finance-sync.md +1 more]
  61  OVERDUE   2026-10-02  Priya Nair          share the Q4 roadmap draft  [2026-09-30-standup.md]
  51  OVERDUE   2026-10-03  Meera Iyer          finalise the Q4 sales targets  [2026-09-30-q4-offsite.md]
  48  done      2026-10-05  Priya Nair          notify customers about the maintenance window  [2026-10-08-billing-go-no-go.md +1 more]
  52  OVERDUE   2026-10-05  Karan Joshi         validate targets against the budget  [2026-09-30-q4-offsite.md]
  63  OVERDUE   2026-10-06  Anita Desai         hand over final designs to dev  [2026-10-01-quote-portal-weekly.md]
  57  OVERDUE   2026-10-07  unassigned          submit their Q4 goals  [2026-09-30-q4-offsite.md]
  62  done      2026-10-07  Rahul Mehta         deploy the beta to staging  [2026-10-13-quote-portal-weekly.md +2 more]
  66  OVERDUE   2026-10-07  Meera Iyer          share the Q4 pipeline forecast  [2026-10-02-finance-sync.md]
  75  OVERDUE   2026-10-08  Priya Nair          write the beta test checklist  [2026-10-06-quote-portal-weekly.md]
  76  OVERDUE   2026-10-08  Rahul (ambiguous)   review Anita's PR  [2026-10-07-standup.md]
  78  OVERDUE   2026-10-08  Priya (ambiguous)   circulate the go/no-go summary  [2026-10-08-billing-go-no-go.md]
  50  OVERDUE   2026-10-09  Karan Joshi         freeze invoice edits  [2026-10-08-billing-go-no-go.md +1 more]
  58  OVERDUE   2026-10-09  Anita Desai         Refresh the brand kit  [2026-09-30-q4-offsite.md]
  65  OVERDUE   2026-10-09  Sam Okafor          cut cloud costs by 10% — proposal  [2026-10-02-finance-sync.md]
  68  OVERDUE   2026-10-09  Meera Iyer          chase Orbit Labs  [2026-10-03-sales-pipeline.md]
  71  OVERDUE   2026-10-09  Lena Fischer        publish the customer quotes  [2026-10-05-onboarding-retro.md]
  79  OVERDUE   2026-10-09  Sam Okafor          confirm rollback plan  [2026-10-08-billing-go-no-go.md]
  49  OVERDUE   2026-10-10  Sam Okafor          schedule cutover  [2026-09-29-billing-cutover-planning.md]
  85  OVERDUE   2026-10-10  Lena Fischer        log the three new leads in CRM  [2026-10-10-sales-weekly.md]
  67  OVERDUE   2026-10-12  Karan Joshi         prepare the board finance slide  [2026-10-02-finance-sync.md]
  81  OVERDUE   2026-10-12  Rahul Verma         patch the outdated express dependency  [2026-10-09-security-review.md]
  70  OVERDUE   2026-10-13  Rahul Verma         start SSO spike  [2026-10-05-onboarding-retro.md]
  84  OVERDUE   2026-10-13  Meera Iyer          send the proposal to Orbit Labs  [2026-10-10-sales-weekly.md]
  73  OVERDUE   2026-10-14  Meera Iyer          demo the portal to Acme  [2026-10-06-quote-portal-weekly.md]
  88  OVERDUE   2026-10-14  Priya Shah          verify invoice totals for the first 50 invoices  [2026-10-12-billing-post-cutover.md]
  53  OVERDUE   2026-10-15  Lena Fischer        run the customer survey  [2026-09-30-q4-offsite.md]
  54  OVERDUE   2026-10-15  Sam Okafor          propose the on-call rotation  [2026-09-30-q4-offsite.md]
  89  OVERDUE   2026-10-15  Karan Joshi         reconcile September ledger  [2026-10-12-billing-post-cutover.md]
  94  OVERDUE   2026-10-15  Karan Joshi         send the final contract to legal  [2026-10-14-acme-renewal-wrapup.md]
  80  OVERDUE   2026-10-16  Sam Okafor          enable MFA on all admin accounts  [2026-10-09-security-review.md]
  91  OVERDUE   2026-10-16  Anita Desai         fix spacing issues flagged in review  [2026-10-13-quote-portal-weekly.md]
  92  OVERDUE   2026-10-20  Priya Nair          collect beta feedback from Acme  [2026-10-13-quote-portal-weekly.md]
  82  open      2026-10-23  Priya Shah          document the incident response steps  [2026-10-09-security-review.md]
  87  open      2026-10-30  Sam Okafor          decommission the old billing DB  [2026-10-12-billing-post-cutover.md]
  95  open      2026-11-30  Lena Fischer        schedule the quarterly business review  [2026-10-14-acme-renewal-wrapup.md]
   6  open      -           Sam Okafor          share the VPN guide  [2026-09-02-standup.md]
  10  open      -           Sam Okafor          snapshot the production DB before cutover  [2026-09-03-billing-migration-sync.md]
  12  open      -           Meera Iyer          ask Acme for their procurement contact  [2026-09-08-quote-portal-weekly.md]
  14  open      -           Priya Shah          set up the test data  [2026-09-09-qa-standup.md]
  18  open      -           unassigned          update the CRM notes  [2026-09-10-acme-renewal-prep.md]
  33  open      -           unassigned          review the prototype before the next review  [2026-09-18-design-review.md]
  34  open      -           unassigned          write the design-system changelog  [2026-09-18-design-review.md]
  38  open      -           Karan Joshi         refund affected customers  [2026-09-21-incident-review.md]
  41  open      -           Sam Okafor          rotate the staging credentials  [2026-09-23-standup.md]
  45  open      -           Lena Fischer        share the usage report with Meera  [2026-09-28-acme-renewal-checkin.md]
  55  open      -           Priya (ambiguous)   own the hiring plan for the two QA roles  [2026-09-30-q4-offsite.md]
  64  open      -           unassigned          decide on the launch date  [2026-10-01-quote-portal-weekly.md]
  69  open      -           Lena Fischer        clean up duplicate leads  [2026-10-03-sales-pipeline.md]
  72  open      -           Priya Shah          review the welcome email for accessibility  [2026-10-05-onboarding-retro.md]
  74  open      -           Sam Okafor          set up uptime monitoring  [2026-10-06-quote-portal-weekly.md]
  77  open      -           Anita Desai         update the style guide  [2026-10-07-standup.md]
  83  done      -           Karan Joshi         revoke access for the two ex-contractors  [2026-10-09-security-review.md]
  86  done      -           Lena Fischer        update the Acme account notes  [2026-10-10-sales-weekly.md]
  90  open      -           Rahul Verma         write the migration runbook  [2026-10-12-billing-post-cutover.md]
  93  open      -           Meera Iyer          follow up on the demo  [2026-10-13-quote-portal-weekly.md]

95 item(s), 61 overdue as of 2026-10-22.
```

Ingest works across all 36 files, and I spot-checked the dates and owners against the notes. Next I'm testing `done`, `followup` and some error cases.

*[Tested `done`, re-ingest, `followup` and error cases. Wrote `.gitignore`, `people.example.json`, `README.md` and `tests/Run-Tests.ps1`. The first test run had 11 failures.]*

```
> .\actiontrack.cmd done 61; .\actiontrack.cmd ingest notes; .\actiontrack.cmd list --owner "Priya Nair"
Marked done: [61] Priya Nair: share the Q4 roadmap draft
Read 32 notes from notes.
Items: 0 new, 0 updated, 118 unchanged. Total stored: 95.
  ID  STATUS    DUE         OWNER               TASK  [latest note]
   1  done      2026-09-11  Priya Nair          send the revised quote to Acme  [2026-09-15-quote-portal-weekly.md +2 more]
  46  OVERDUE   2026-10-02  Priya Nair          prepare the renewal one-pager  [2026-10-14-acme-renewal-wrapup.md +1 more]
  61  done      2026-10-02  Priya Nair          share the Q4 roadmap draft  [2026-09-30-standup.md]
  48  done      2026-10-05  Priya Nair          notify customers about the maintenance window  [2026-10-08-billing-go-no-go.md +1 more]
  75  OVERDUE   2026-10-08  Priya Nair          write the beta test checklist  [2026-10-06-quote-portal-weekly.md]
  92  OVERDUE   2026-10-20  Priya Nair          collect beta feedback from Acme  [2026-10-13-quote-portal-weekly.md]

6 item(s), 3 overdue as of 2026-10-22.
--- followup ambiguous:
Error: 'Priya' matches Priya Nair and Priya Shah. Use the full name in quotes.
exit=1
--- followup dry run:
Note: 3 open item(s) belong to 'Priya (ambiguous)' and are not in this email.
Note: no email for 'Priya Nair' in people.json; 'to' is left empty.
To:
Subject: Follow-up: 3 open action item(s), 3 overdue

Hi Priya,

Following up on the action items from our recent meetings that are still open.

Overdue:
  - Prepare the renewal one-pager (due Fri 2 Oct 2026; from Acme renewal wrap-up, 2026-10-14)
  - Write the beta test checklist (due Thu 8 Oct 2026; from Quote portal weekly, 2026-10-06)
  - Collect beta feedback from Acme (due Tue 20 Oct 2026; from Quote portal weekly, 2026-10-13)

Could you reply with a quick status on each, or let me know if any are already done?

Thanks

(dry run: nothing written, nothing sent)
--- errors:
Error: no item with id 999
Error: --status must be open, done or overdue
Error: folder not found: nope
  ID  STATUS    DUE         OWNER               TASK  [latest note]
   3  OVERDUE   2026-09-03  Anita Desai         share first wireframes  [2026-09-01-quote-portal-kickoff.md]
   5  OVERDUE   2026-09-03  Rahul Mehta         open the repo access request  [2026-09-02-standup.md]
   8  OVERDUE   2026-09-07  Rahul Verma         review the schema mapping doc  [2026-09-17-billing-migration-sync.md +1 more]
  11  OVERDUE   2026-09-09  Rahul Mehta         finish login screen  [2026-09-08-quote-portal-weekly.md]

4 item(s), 4 overdue as of 2026-10-22.

> powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-Tests.ps1
FAIL: duplicate quote item merged
  expected: 1
  actual:   14
FAIL: later [x] closes it
  expected: done
  actual:
FAIL: latest due date wins
  expected: 2026-09-24
  actual:
FAIL: ambiguous Priya
  expected: 1
  actual:   14
FAIL: table row read
  expected: 1
  actual:   14
FAIL: ACTION: line read
  expected: 1
  actual:   14
FAIL: file-name date fallback
  expected: 1
  actual:   14
FAIL: overdue at run time
  expected: True
  actual:   False
FAIL: done succeeds
  expected: 0
  actual:   1
FAIL: manual done not reopened
  expected: manual
  actual:
FAIL: draft skips done item
  expected: False
  actual:   True

11 failed, 47 passed
exit=1
```

The failures come from how the test helper returns results, not from the tool. PowerShell unwraps a one-item list, so `.Count` was counting the item's fields (14). Fixing the helper:

*[Fixed the test helper. All 58 checks passed. Deleted the test `data.json`.]*

```
> powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-Tests.ps1
All 58 checks passed
exit=0

> Remove-Item data.json; (list project files other than notes)
lib\Commands.ps1
lib\Dates.ps1
lib\Owners.ps1
lib\Parser.ps1
lib\Store.ps1
tests\Run-Tests.ps1
.gitignore
actiontrack.cmd
actiontrack.ps1
people.example.json
```

actiontrack is built and working. It's written in PowerShell, as you chose, so there's nothing to install. I ran it on all 36 sample files, and all 58 automatic checks pass.

**How to run it** (from the project folder):
```bash
.\actiontrack.cmd ingest notes
```
```bash
.\actiontrack.cmd list --status overdue
```
```bash
.\actiontrack.cmd followup "Priya Nair" --dry-run
```

**What ingest found:**
- **Read:** 32 notes, giving 95 unique items. 23 repeat mentions were merged into existing items.
- **Skipped and reported:** 3 files. One is empty (`notes-final-v2`), `scratch.md` is binary, and `untitled.md` has no date anywhere. The `.txt` file was ignored.
- **Warnings:** the sales-pipeline note's date ("sometime last week") fell back to the date in its file name, and the 23 Sep standup has no attendee list.
- **No clear owner:** 11 items. 6 say "Priya" or "Rahul" when both people with that name were present, and 5 say Everyone, Team or TBD. They show in `list` but are never emailed.
- **Overdue as of today (22 Oct):** 61 items, shown in red with an `OVERDUE` label.
- **Traps:** the quoted "refund by Friday" line, the auditor's template line and the HTML-comment task were all correctly ignored.

**Your five changes:**
1. **Ticks and manual done:** a later `[x]` only closes an item when the owner and task match. `done <id>` always wins; I tested that a second ingest doesn't reopen it.
2. **Overdue:** it's worked out every time you run a command and never saved. Use `--today 2026-10-22` or the `ACTIONTRACK_TODAY` setting to fix the date.
3. **followup:** it writes `drafts/<owner>.json` (to, subject, body) and `--dry-run` only prints the email. It never sends.
4. **Personal files:** `.gitignore` covers `people.json`, `data.json` and `drafts/`. Only `people.example.json` is meant to be committed.
5. **README:** [README.md](README.md) has an Assumptions section covering date rules, owner matching, duplicates and skipped files.

**Things to know:**
- **Two items to fix by hand:** "Rahul to review Anita's PR" and "Priya to circulate the go/no-go summary" are flagged "(ambiguous)". Both people with that first name were in the room, so the tool refuses to guess. Right now you'd fix the owner by editing `data.json`. A small `assign <id> <name>` command would make this easier, and I can add it if you like.
- **Running it:** `actiontrack.cmd` exists because this computer blocks PowerShell scripts by default. It allows scripts for that single run only and doesn't change any settings.
- **Gmail:** I don't see a Gmail connector in this session, so no draft has been created yet. Once you connect Gmail and run `followup`, I can create the drafts from the `drafts/` files using "create draft" only.
- **Git:** Git isn't installed, so nothing has been committed.
- **Data reset:** I deleted the `data.json` from my test runs, so your first `ingest` starts fresh.

Files are in a folder the app made for this session:
- [actiontrack.cmd](actiontrack.cmd) and [actiontrack.ps1](actiontrack.ps1): how you run it
- `lib/`: the code, in five files
- [tests/Run-Tests.ps1](tests/Run-Tests.ps1): the automatic checks
- [people.example.json](people.example.json): copy to `people.json` and fill in real email addresses

---

## 4. User

followup "Priya Nair

## 4. Claude

*[Ran `ingest notes`, then `followup "Priya Nair"`, which wrote `drafts/priya-nair.json`.]*

```
> .\actiontrack.cmd ingest notes; .\actiontrack.cmd followup "Priya Nair"; Get-Content drafts\priya-nair.json
Read 32 notes from notes.
Items: 95 new, 23 updated, 0 unchanged. Total stored: 95.
Note: 3 open item(s) belong to 'Priya (ambiguous)' and are not in this email.
Note: no email for 'Priya Nair' in people.json; 'to' is left empty.
To:
Subject: Follow-up: 4 open action item(s), 4 overdue

Hi Priya,

Following up on the action items from our recent meetings that are still open.

Overdue:
  - Prepare the renewal one-pager (due Fri 2 Oct 2026; from Acme renewal wrap-up, 2026-10-14)
  - Share the Q4 roadmap draft (due Fri 2 Oct 2026; from Team standup, 2026-09-30)
  - Write the beta test checklist (due Thu 8 Oct 2026; from Quote portal weekly, 2026-10-06)
  - Collect beta feedback from Acme (due Tue 20 Oct 2026; from Quote portal weekly, 2026-10-13)

Could you reply with a quick status on each, or let me know if any are already done?

Thanks

Draft saved to drafts\priya-nair.json. Nothing was sent.
Next: ask Claude to create the Gmail draft from this file (Gmail "create draft" only).
exit=0
{
    "owner":  "Priya Nair",
    "to":  "",
    "subject":  "Follow-up: 4 open action item(s), 4 overdue",
    "body":  "Hi Priya,\n\nFollowing up on the action items from our recent meetings that are still open.\n\nOverdue:\n  - Prepare the renewal one-pager (due Fri 2 Oct 2026; from Acme renewal wrap-up, 2026-10-14)\n  - Share the Q4 roadmap draft (due Fri 2 Oct 2026; from Team standup, 2026-09-30)\n  - Write the beta test checklist (due Thu 8 Oct 2026; from Quote portal weekly, 2026-10-06)\n  - Collect beta feedback from Acme (due Tue 20 Oct 2026; from Quote portal weekly, 2026-10-13)\n\nCould you reply with a quick status on each, or let me know if any are already done?\n\nThanks",
    "item_ids":  [
                     46,
                     61,
                     75,
                     92
                 ],
    "as_of":  "2026-10-22"
}
```

The draft file is written (4 overdue items for Priya Nair). Now creating it as a Gmail **draft** only, with no recipient yet since `people.json` has no address for her.

*[Created the Gmail draft with the connector's "create draft" tool. Nothing was sent.]*

```
Gmail create_draft (subject and body as above, no recipient) ->
{"id":"r-6208475184935279614","messageId":"1a162eecbe6d7a09","threadId":"1a162eecbe6d7a09","viewUrl":"https://mail.google.com/mail/?authuser=[your-email]#all?compose=thread-f:1879741488815766025%2Bmsg-a:r-6208475184935279614"}
```

Priya Nair's follow-up is now a draft in your Gmail. Nothing was sent: [open the draft](https://mail.google.com/mail/?authuser=[your-email]#all?compose=thread-f:1879741488815766025%2Bmsg-a:r-6208475184935279614)

**What's in it:** 4 items, all overdue as of today (22 Oct):
- Prepare the renewal one-pager (was due 2 Oct)
- Share the Q4 roadmap draft (was due 2 Oct)
- Write the beta test checklist (was due 8 Oct)
- Collect beta feedback from Acme (was due 20 Oct)

**Before you send it:**
- **"To" is empty.** There's no `people.json` yet, so the tool doesn't know her address. Add it in Gmail, or copy `people.example.json` to `people.json` with real addresses before the next run.
- **3 more "Priya" items are left out.** Both Priyas were in the meetings for these, so the tool can't tell whose they are: sign off the cutover checklist, own the QA hiring plan, and circulate the go/no-go summary. If any are hers, add them to the email yourself.

I re-ran `ingest` first, because I had deleted my test data last turn. A copy of the email is also saved in `drafts/priya-nair.json`.

---

## 5. User

Please save our full conversation so far as claude-code-chat.md with my messages and your replies in order, nothing removed.

## 5. Claude

*[Saved this file.]*

I saved the conversation as claude-code-chat.md, with your messages and my replies in order. Tool steps were short bracketed notes, without their full output.

---

## 6. User

no issue Just do that

## 6. Claude

*[Added the output of every tool step under its bracketed note.]*
