# actiontrack: Implementation Document

| | |
|---|---|
| Version | 1.0 |
| Date | 22 October 2026 |
| Language | Windows PowerShell 5.1 (also PowerShell 7) |
| Related | `docs/requirements-specification.md`, `docs/test-cases.md`, `README.md` |

## 1. Overview

actiontrack is a command-line tool made of one entry script and five small
library files. It has no external dependencies. Data lives in one JSON file.
Emails are written as JSON draft files; Claude Code turns them into Gmail drafts.

```
 notes/*.md ──► Parser ──► Dates + Owners ──► Store (data.json) ──► list / done / assign
                                                     │
                                                     └──► followup ──► drafts/<owner>.json
                                                                            │
                                         Claude Code + Gmail "create draft" ◄┘
                                         (never send)
```

### Why these choices
| Decision | Reason |
|---|---|
| PowerShell instead of Python | Python, Node and Git were not installed; PowerShell is built into Windows, so nothing to install. |
| One JSON data file | Easy to open and inspect; no database needed for ~100 items. |
| Draft files instead of calling Gmail | The tool can never send by mistake; the Gmail connector is only available to Claude Code. |
| `actiontrack.cmd` wrapper | Windows blocks `.ps1` scripts by default; the wrapper allows them for that one run only, without changing settings. |

## 2. Modules

| File | Responsibility | Main functions |
|---|---|---|
| `actiontrack.ps1` | Entry point. Loads the libraries and returns the exit code. | — |
| `actiontrack.cmd` | Windows launcher with `-ExecutionPolicy Bypass` for one run. | — |
| `lib/Commands.ps1` | Parses options and runs each command. Catches every error so the tool never crashes. | `Invoke-ActionTrack`, `Invoke-Ingest`, `Invoke-List`, `Invoke-Done`, `Invoke-Assign`, `Invoke-Followup` |
| `lib/Parser.ps1` | Reads one note: checks it's readable, finds title, date, attendees and raw action items. | `Read-NoteFile`, `Split-ItemText` |
| `lib/Dates.ps1` | Turns date phrases into real dates relative to the meeting date. | `Resolve-DatePhrase`, `Split-DueDate`, `ConvertFrom-MeetingDate` |
| `lib/Owners.ps1` | Turns written names into full names, "(ambiguous)" or "unassigned"; builds the task key. | `Split-OwnerText`, `Resolve-Owner`, `Get-TaskKey` |
| `lib/Store.ps1` | Loads/saves `data.json`; merges repeats; applies done/reopen rules; reassigns owners. | `Read-Store`, `Save-Store`, `Add-Mention`, `Set-ItemOwner`, `Test-Overdue` |
| `tests/Run-Tests.ps1` | 65 automated checks with a temporary data file. | `Assert-Equal` |

## 3. Data model

`data.json`:

```json
{
  "next_id": 96,
  "items": [
    {
      "id": 1,
      "owner": "Priya Nair",
      "task": "send the revised quote to Acme",
      "task_key": "send revised quote to acme",
      "due": "2026-09-11",
      "due_raw": "by Friday",
      "due_set_on": "2026-09-08",
      "status": "done",
      "done_by": "note",
      "done_on": "2026-09-15",
      "sources": ["2026-09-01-quote-portal-kickoff.md", "2026-09-08-quote-portal-weekly.md", "2026-09-15-quote-portal-weekly.md"],
      "first_seen": "2026-09-01",
      "last_seen": "2026-09-15",
      "last_meeting": "Quote portal weekly, 2026-09-15"
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `owner` | Full name, `"<First> (ambiguous)"` or `"unassigned"`. |
| `task_key` | Simplified task text (lower case, no punctuation, no "the/a/an", no due phrase). With `owner` it identifies an item. |
| `due` / `due_raw` / `due_set_on` | Resolved date, the original words, and the meeting that set it. |
| `status` | `open` or `done`. **Overdue is never stored.** |
| `done_by` | `note` (ticked `[x]` in a note) or `manual` (`done` command). |
| `original_owner` | Only present after `assign`: the owner the notes use, so re-ingest still finds the item. |

`drafts/<owner>.json`: `owner`, `to`, `subject`, `body`, `item_ids`, `as_of`.

`people.json` (local only): `{ "Full Name": "email" }`.

## 4. How each command works

### 4.1 ingest
1. List the folder. Non-`.md` files are reported as ignored.
2. For each `.md` file, `Read-NoteFile`:
   - rejects empty, binary (NUL bytes), non-UTF-8 or garbled files;
   - strips HTML comments; skips code blocks and `>` quotes;
   - reads front matter or `Date:` / `Attendees:` lines;
   - collects checkbox lines, `ACTION:` lines and Owner/Action table rows;
   - falls back to the file-name date if the `Date:` text can't be read; throws if there's no date at all.
   Any error skips that file with its reason.
3. Collect every attendee from every note (the "everyone" list).
4. Process notes **oldest meeting first**. For each raw item:
   - `Split-DueDate` finds the due phrase at the end of the line and resolves it;
   - `Split-OwnerText` splits "Anita & Rahul" into two owners;
   - `Resolve-Owner` matches each owner name;
   - `Add-Mention` creates or updates the stored item.
5. Save, then print the summary, skipped files, warnings and items needing an owner.

### 4.2 list
Loads the store, applies filters, sorts by due date (no date last), and
prints rows. `Test-Overdue` (open and due < today) decides the red `OVERDUE` label.

### 4.3 done
Sets `status = done`, `done_by = manual`. `Add-Mention` never reopens a manual done.

### 4.4 assign
`Resolve-KnownOwner` accepts a full name, or a first name only if one person
has it. `Set-ItemOwner` stores `original_owner` and indexes the item under both
names, so the next ingest updates this item instead of creating a new ambiguous one.

### 4.5 followup
Resolves the owner, takes their open items, splits them into overdue and
still-open, looks up the email in `people.json`, builds plain-text subject and
body, and writes `drafts/<slug>.json` (or only prints with `--dry-run`).
Claude Code then calls the Gmail **create draft** tool with that content.

## 5. Key rules in detail

### 5.1 Due dates (`Dates.ps1`)
- Only a phrase **at the end of the line** after `by / due / on / from / for / before / until` counts, and the whole phrase must be a date. This is why "by 10% - proposal by 2026-10-09" gives 9 Oct.
- Weekday = next one strictly after the meeting; "next <weekday>" adds a week.
- Day + month without a year uses the meeting's year, unless that's more than 6 months before the meeting (then next year).
- Full rules: README "Assumptions → Due dates".

### 5.2 Owners (`Owners.ps1`)
1. Group words (everyone, team, TBD, ...) → `unassigned`.
2. Exact full name → that person.
3. First name (+ optional last initial): check this meeting's attendees, then everyone. One match → that person; two or more → "(ambiguous)"; none → keep the name as written.

### 5.3 Duplicates and status (`Store.ps1` → `Add-Mention`)
- Key = owner + task key.
- Newest wording and newest stated due date win.
- `[x]` closes an open item; a later open mention reopens an item closed by an **older note**; a **manual** done is never reopened.
- Because notes are replayed in date order, re-running ingest gives the same result (no duplicates, same IDs).

## 6. Error handling

- Every command runs inside one `try/catch` in `Invoke-ActionTrack`: errors print `Error: ...` in red and return exit code 1.
- A bad note never stops ingest; it's listed under "Skipped".
- `data.json` is written to a temporary file first and then moved into place, so a crash can't leave a half-written file.

## 7. Security and privacy

- No email is ever sent: the tool has no email code; Claude Code may only use Gmail "create draft"; `.claude/settings.json` denies the Gmail send, reply and forward tools.
- `data.json`, `people.json` and `drafts/` are in `.gitignore`.
- Only `example.com` addresses appear in the repository.

## 8. Testing

`tests/Run-Tests.ps1` loads the libraries directly, sets `ACTIONTRACK_DATA` to
a temporary folder and `ACTIONTRACK_TODAY` to 2026-10-22, and runs 65 checks
(unit checks for dates and owners, plus full runs over `notes/`). See
`docs/test-cases.md` for the list.

## 9. Extending

| Change | Where |
|---|---|
| New date phrase | Add a rule in `Resolve-DatePhrase` and a test in section 1 of the tests. |
| New action-item format | Add a pattern in the line loop of `Read-NoteFile`. |
| New group word ("all hands") | Add it to `$GroupOwners` in `Owners.ps1`. |
| New command | Add an `Invoke-<Name>` function and a `switch` case in `Invoke-ActionTrack`, then update the usage text, README and CLAUDE.md. |

## 10. Known limitations

See README "Known limitations".
