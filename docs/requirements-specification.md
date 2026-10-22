# actiontrack: Requirements Specification

| | |
|---|---|
| Version | 1.0 |
| Date | 22 October 2026 |
| Owner | Sapna Sanarkar (Project Manager) |
| Status | Implemented |

## 1. Purpose

Project teams keep meeting notes as markdown files. Action items get lost
between meetings, due dates slip without anyone noticing, and following up
with each owner is manual work. **actiontrack** is a small command-line tool
that reads those notes, keeps one list of action items, highlights what is
overdue, and prepares follow-up emails as Gmail **drafts** that a person
reviews and sends.

## 2. Scope

**In scope**
- Reading a folder of markdown meeting notes.
- Extracting action items with owner, task, due date, source note and status.
- Listing and filtering items; marking items done; fixing unclear owners.
- Writing one follow-up email per owner and creating it as a Gmail draft.

**Out of scope**
- Sending email of any kind.
- Editing the meeting notes themselves.
- Calendars, reminders, or scheduling.
- A graphical user interface.

## 3. Users

| User | Needs |
|---|---|
| Project manager | See every open and overdue action across meetings, chase owners quickly. |
| Claude Code (assistant) | Run the tool, explain results, and create Gmail drafts from the tool's output. |

## 4. Functional requirements

### FR-1 Ingest notes: `actiontrack ingest <folder>`
| ID | Requirement |
|---|---|
| FR-1.1 | Read every `.md` file directly inside the folder. Ignore other file types and report them. |
| FR-1.2 | Read the meeting date and attendees from either `Date:` / `Attendees:` lines or a `---` front-matter block. |
| FR-1.3 | Recognise action items written as checkboxes (`- [ ]`, `* [ ]`, `+ [ ]`, `[x]`, `[X]`, indented), `ACTION:` lines, and tables with Owner and Action/Task columns. |
| FR-1.4 | Ignore task-like lines inside quotes, code blocks and HTML comments. |
| FR-1.5 | Store for each item: owner, task, due date, source file(s), and status (open/done). |
| FR-1.6 | Resolve due dates to real calendar dates relative to the meeting date ("by Friday", "tomorrow", "10 Sep", "end of month", ...). |
| FR-1.7 | Resolve owners to full names using attendee lists ("Priya N.", "@anita", "Rahul"). |
| FR-1.8 | Merge duplicates of the same item across meetings (same owner + same task). |
| FR-1.9 | Re-running ingest must not create duplicates and must keep item IDs. |
| FR-1.10 | Print a summary: notes read, items new/updated, skipped files with reasons, warnings, items with no clear owner. |

### FR-2 List items: `actiontrack list`
| ID | Requirement |
|---|---|
| FR-2.1 | Show ID, status, due date, owner, task and latest source note. |
| FR-2.2 | Filter by `--owner`, `--status open\|done\|overdue` and `--due-before <date>`. Filters can be combined. |
| FR-2.3 | Overdue items must be clearly highlighted (red text and an `OVERDUE` label). |
| FR-2.4 | Overdue = open and due date before today. Computed at run time, never stored. |
| FR-2.5 | "Today" can be set with `--today` or the `ACTIONTRACK_TODAY` variable so results are repeatable. |

### FR-3 Mark done: `actiontrack done <id>`
| ID | Requirement |
|---|---|
| FR-3.1 | Mark the item done. |
| FR-3.2 | A manual `done` always wins: no later meeting note can reopen it. |

### FR-4 Fix owners: `actiontrack assign <id> <owner>`
| ID | Requirement |
|---|---|
| FR-4.1 | Give an ambiguous or unassigned item a real owner. |
| FR-4.2 | The new owner must be a known person; an ambiguous first name is refused. |
| FR-4.3 | Re-ingest keeps the new owner and does not recreate the ambiguous item. |

### FR-5 Follow-up: `actiontrack followup <owner>`
| ID | Requirement |
|---|---|
| FR-5.1 | Build one email per owner covering their open and overdue items (overdue listed first). |
| FR-5.2 | Write it to `drafts/<owner>.json` with `to`, `subject` and `body`. |
| FR-5.3 | `--dry-run` prints the email and writes nothing. |
| FR-5.4 | The email address comes from a local `people.json`; if missing, `to` is empty and a warning is shown. |
| FR-5.5 | The tool must **never send** email. The Gmail draft is created by Claude Code with the Gmail connector's "create draft" tool only. |

## 5. Edge cases (must be handled)

| ID | Case | Required behaviour |
|---|---|---|
| EC-1 | Same item in several meetings | One item; newest due date wins; every source remembered. |
| EC-2 | Later `[x]` for an earlier item | Closes it only when owner and task both match. |
| EC-3 | Item with no owner (Everyone, Team, TBD...) | Stored as `unassigned`; shown in `list`; never emailed. |
| EC-4 | Item with no due date | Stored with no date; never overdue. |
| EC-5 | Two people with the same first name in the meeting | Owner stored as "Name (ambiguous)"; never guessed; never emailed until assigned. |
| EC-6 | Malformed note (empty, binary, no date) | Skipped and reported; the tool never crashes. |
| EC-7 | Unreadable meeting date but date in file name | Use the file-name date and warn. |
| EC-8 | Invalid command input (bad id, status, date) | Clear error message and exit code 1; no crash. |

## 6. Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | Runs on Windows with no installation (Windows PowerShell 5.1). Mac/Linux via PowerShell 7. |
| NFR-2 | Simple to read and maintain for a non-specialist; plain JSON data file. |
| NFR-3 | Personal data stays local: `data.json`, `people.json` and `drafts/` are never committed. |
| NFR-4 | No real email addresses in the repository. |
| NFR-5 | Automated tests with a fixed "today" so results never change from day to day. |
| NFR-6 | Built and testable within about one hour. |

## 7. Assumptions

The detailed rules for date resolution, owner matching, duplicates and skipped
files are listed in the README's "Assumptions" section and were approved
before implementation.

## 8. Acceptance criteria

- All automated tests pass (`tests/Run-Tests.ps1`).
- Running on the 36 sample notes skips the 3 broken files with reasons, ignores the `.txt` file and never crashes.
- `followup` creates a draft file; a Gmail draft is created only with "create draft"; nothing is ever sent.
