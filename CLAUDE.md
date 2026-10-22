# actiontrack

A small command-line tool that reads markdown meeting notes, tracks the action
items in them (owner, task, due date, source note, status), and prepares
follow-up emails as drafts. Written in Windows PowerShell 5.1 with no
dependencies. README.md has the full list of assumptions.

## Running it

On Windows, always go through the wrapper (it bypasses the script policy for
that one run only):

```
.\actiontrack.cmd <command> [options]
```

On Mac/Linux use PowerShell 7: `pwsh ./actiontrack.ps1 <command> [options]`.

## Commands

| Command | Purpose |
|---|---|
| `ingest <folder>` | Read every `.md` note into `data.json`. Safe to re-run. Reports skipped files, warnings and items with no clear owner. |
| `list [--owner X] [--status open\|done\|overdue] [--due-before yyyy-mm-dd] [--today yyyy-mm-dd]` | Show items; overdue rows are red and labelled `OVERDUE`. |
| `done <id>` | Mark an item done by hand. A later meeting can never reopen it. |
| `assign <id> "<Full Name>"` | Give an `(ambiguous)` or `unassigned` item a real owner. Survives re-ingest. |
| `followup "<Full Name>" [--dry-run] [--today yyyy-mm-dd]` | Write one email (to, subject, body) for the owner's open and overdue items to `drafts/<owner>.json`. `--dry-run` only prints it. |

"Today" comes from `--today`, else `ACTIONTRACK_TODAY`, else the computer's
date. Overdue is computed at run time and never stored. `ACTIONTRACK_DATA`
overrides the data file location.

## File structure

```
actiontrack.cmd        Windows entry point (wraps actiontrack.ps1)
actiontrack.ps1        entry point
lib/Commands.ps1       ingest, list, done, assign, followup
lib/Parser.ps1         reads one note (front matter, Date/Attendees, checkboxes, tables, ACTION: lines)
lib/Dates.ps1          "by Friday" -> real date, relative to the meeting date
lib/Owners.ps1         "Priya N." / "@anita" -> full name, "(ambiguous)" or "unassigned"
lib/Store.ps1          data.json, duplicate merging, done/reopen rules, assign
tests/Run-Tests.ps1    automatic checks
notes/                 sample meeting notes (some deliberately broken)
docs/                  sample output and conversation logs
people.example.json    template for people.json (name -> email)
```

## Tests

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Run-Tests.ps1
```

Tests use a temporary data file and a fixed today of 2026-10-22. Run them
after every change; they must all pass.

## Rules

- `followup` must NEVER send an email. It only writes `drafts/<owner>.json`.
  Claude then creates a Gmail **draft** from that file with the Gmail
  "create draft" tool. Never use a Gmail send, reply or forward tool.
- Never commit `data.json`, `people.json` or `drafts/` (they are in `.gitignore`).
- Never put real email addresses in the repository. Use `example.com`
  addresses in examples; real ones belong only in the local `people.json`.
- Keep `.ps1` files ASCII-only: Windows PowerShell 5.1 reads BOM-less files
  in the system code page.
