# Sample output

Real output from the sample notes in `notes/`, run with a fresh data file and
"today" fixed to 2026-10-22:

```
$env:ACTIONTRACK_TODAY = '2026-10-22'
```

On screen, overdue rows are red; colours are not shown here.

## `.\actiontrack.cmd ingest notes`

```
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

11 item(s) have no clear owner and are never emailed (fix with: actiontrack assign <id> <owner>):
  - [18] unassigned: update the CRM notes  (2026-09-10-acme-renewal-prep.md)
  - [27] Priya (ambiguous): sign off the cutover checklist  (2026-09-17-billing-migration-sync.md)
  - [33] unassigned: review the prototype before the next review  (2026-09-18-design-review.md)
  - [34] unassigned: write the design-system changelog  (2026-09-18-design-review.md)
  - [40] Rahul (ambiguous): rebase the feature branch  (2026-09-23-standup.md)
  - [55] Priya (ambiguous): own the hiring plan for the two QA roles  (2026-09-30-q4-offsite.md)
  - [56] Rahul (ambiguous): prepare the architecture overview  (2026-09-30-q4-offsite.md)
  - [57] unassigned: submit their Q4 goals  (2026-09-30-q4-offsite.md)
  - [64] unassigned: decide on the launch date  (2026-10-01-quote-portal-weekly.md)
  - [76] Rahul (ambiguous): review Anita's PR  (2026-10-07-standup.md)
  - [78] Priya (ambiguous): circulate the go/no-go summary  (2026-10-08-billing-go-no-go.md)
```

"23 updated" means 23 mentions were repeats of items already seen in earlier
meetings (same owner and task), so they were merged instead of duplicated.

## `.\actiontrack.cmd list --status overdue` (first 10 rows)

```
  ID  STATUS    DUE         OWNER               TASK  [latest note]
   3  OVERDUE   2026-09-03  Anita Desai         share first wireframes  [2026-09-01-quote-portal-kickoff.md]
   5  OVERDUE   2026-09-03  Rahul Mehta         open the repo access request  [2026-09-02-standup.md]
   8  OVERDUE   2026-09-07  Rahul Verma         review the schema mapping doc  [2026-09-17-billing-migration-sync.md +1 more]
  11  OVERDUE   2026-09-09  Rahul Mehta         finish login screen  [2026-09-08-quote-portal-weekly.md]
   9  OVERDUE   2026-09-11  Priya Shah          draft the test plan for invoice rounding  [2026-09-03-billing-migration-sync.md]
  13  OVERDUE   2026-09-11  Karan Joshi         send the vendor invoice list  [2026-09-09-qa-standup.md]
  15  OVERDUE   2026-09-11  Lena Fischer        pull Acme's usage report for the last 6 months  [2026-09-10-acme-renewal-prep.md]
  16  OVERDUE   2026-09-14  Karan Joshi         confirm discount ceiling with the CFO  [2026-09-10-acme-renewal-prep.md]
  26  OVERDUE   2026-09-18  Meera Iyer          update the pipeline sheet  [2026-09-16-standup.md]
  25  OVERDUE   2026-09-21  Lena Fischer        draft the case study outline  [2026-09-16-standup.md]
  ... (51 more rows)

61 item(s), 61 overdue as of 2026-10-22.
```

## `.\actiontrack.cmd followup "Priya Nair" --dry-run`

```
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

(dry run: nothing written, nothing sent)
```

Without `--dry-run`, the same email is written to `drafts/priya-nair.json`.
Claude Code then turns that file into a Gmail draft (never sent).
