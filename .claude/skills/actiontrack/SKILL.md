---
name: actiontrack
description: Track action items from markdown meeting notes and prepare follow-up emails as Gmail drafts. Use when the user wants to collect action items from meeting notes, see what is open or overdue, mark items done, fix unclear owners, or draft follow-up emails to owners.
---

# actiontrack

Run every command from the project root. On Windows use `.\actiontrack.cmd`;
on Mac/Linux use `pwsh ./actiontrack.ps1`. Never send email.

## Steps

1. **Ingest the notes.**
   `.\actiontrack.cmd ingest notes` (or the folder the user names).
   It is safe to re-run; it never duplicates items.

2. **Review what ingest reported** and tell the user, in plain words:
   - **Skipped files**, with the reason for each (empty, binary, no date).
   - **Warnings**, e.g. a date taken from the file name or a note with no attendee list.
   - **Items with no clear owner**: `Priya (ambiguous)`, `Rahul (ambiguous)` or
     `unassigned`. These are never emailed. Ask the user who owns each one, then
     run `.\actiontrack.cmd assign <id> "<Full Name>"`. Never guess an owner.

3. **List overdue items.**
   `.\actiontrack.cmd list --status overdue`. Add `--owner "<name>"` or
   `--due-before yyyy-mm-dd` when the user asks. Overdue means the due date is
   before today. Pass `--today yyyy-mm-dd` only if the user gives a date.

4. **Mark items done** only when the user says they are done:
   `.\actiontrack.cmd done <id>`. A later meeting can never reopen them.

5. **Preview each follow-up first.**
   `.\actiontrack.cmd followup "<Full Name>" --dry-run`. Show the user the
   email and point out any warning (missing email address, ambiguous items left out).

6. **Write the draft file** once the user is happy:
   `.\actiontrack.cmd followup "<Full Name>"`. This writes `drafts/<slug>.json`
   with `to`, `subject` and `body`. It sends nothing.

7. **Create the Gmail draft, never send.**
   Read `drafts/<slug>.json` and call the Gmail connector's **create draft**
   tool with its `to` (leave empty if blank), `subject` and `body` as plain text.
   Never call a Gmail send, reply or forward tool. Give the user the draft link
   and remind them to review and send it themselves.

## Rules

- Never commit `data.json`, `people.json` or `drafts/`.
- Never put real email addresses into repository files.
