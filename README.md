# actiontrack

A small command-line tool that reads markdown meeting notes, keeps track of the
action items in them, and prepares follow-up emails as **drafts** (it never sends).

Written in Windows PowerShell 5.1, so there is nothing to install on Windows.

## Quick start

From this folder, in PowerShell or Command Prompt:

```
.\actiontrack.cmd ingest notes
.\actiontrack.cmd list --status overdue
.\actiontrack.cmd done 12
.\actiontrack.cmd followup "Priya Nair" --dry-run
.\actiontrack.cmd followup "Priya Nair"
```

`actiontrack.cmd` runs `actiontrack.ps1` with `-ExecutionPolicy Bypass` for that
one run only. It does not change the computer's script policy.

For email addresses, copy `people.example.json` to `people.json` and fill in real
addresses. `people.json` is ignored by git.

## Commands

| Command | What it does |
|---|---|
| `ingest <folder>` | Reads every `.md` file in the folder and saves the items to `data.json`. Safe to run again: no duplicates are created. Prints which files were skipped and why. |
| `list` | Shows items. Filters: `--owner <name>` (part of a name is fine, e.g. `Priya`), `--status open\|done\|overdue`, `--due-before <yyyy-mm-dd>`. Overdue items are shown in **red** with the label `OVERDUE`. |
| `done <id>` | Marks an item done by hand. |
| `followup <owner>` | Builds one email covering the owner's open and overdue items. It writes the email to `drafts/<owner>.json` (to, subject, body). `--dry-run` only prints it. |

**What "today" is:** overdue means *due date is before today*. It is worked out
every time you run the tool and is never saved. "Today" is `--today <yyyy-mm-dd>`
if given, else the `ACTIONTRACK_TODAY` environment variable, else the computer's
date. Tests set it so results don't change from day to day.

Other settings: `ACTIONTRACK_DATA` changes where the data file lives (default
`./data.json`). Set `NO_COLOR=1` to turn colours off (the `OVERDUE` label stays).

## Gmail: drafts only

`followup` never sends anything and doesn't connect to Gmail itself. It writes
`drafts/<owner>.json`. Claude then creates the Gmail draft from that file using
the Gmail connector's **create draft** tool only, never send. You review and send
it yourself in Gmail.

## Assumptions

### Which files are read
- Only `.md` files directly inside the folder are read. Other files (e.g. `.txt`) are listed as "ignored".
- A file is **skipped and reported** (never a crash) when it is empty, contains binary or garbled data, isn't valid UTF-8 text, or has no meeting date at all.
- **Meeting date**: from a `Date:` line or a `date:` line in a `---` front-matter block. Accepted styles: `2026-09-08`, `9 September 2026`, `Monday, 14 September 2026`, `September 9, 2026`. A year is required.
- If the date can't be understood (e.g. "sometime last week") but the file name starts with a date (`2026-10-03-...`), that date is used and a warning is shown.
- A note with no attendee list is still read, with a warning (see owner matching).

### Which lines count as action items
- Checkbox lines anywhere in the note: `- [ ]`, `* [ ]`, `+ [ ]` (open) and `[x]` / `[X]` (done). Indented sub-items count too.
- `ACTION: Karan to ...` lines.
- Rows of a markdown table whose header has an `Owner` column and an `Action` or `Task` column (plus an optional `Due` column).
- **Not counted**: lines inside quotes (`>`), code blocks (```` ``` ````) or HTML comments (`<!-- -->`). These are other people's words, templates or cut items.
- The owner is the text before the first " to " (`Priya to send ...`), or `@name:` at the start. If there isn't one, the item is **unassigned**.

### Due dates (counted from the meeting date)
- The due date must be at the **end** of the line, after `by`, `due`, `on`, `from`, `for`, `before` or `until`. Example: "cut costs by 10% - proposal by 2026-10-09" is due 9 Oct, because "10%" is not a date.
- A weekday ("by Friday", "Wed") means the next one **after** the meeting day. A Friday meeting saying "by Friday" means the following Friday.
- "next Tuesday" = one week after the plain "Tuesday".
- "tomorrow" = meeting + 1 day. "EOD" / "today" = the meeting day. "EOD tomorrow" = meeting + 1 day.
- "end of week" = the Friday of that week. "end of next week" = the Friday after that.
- "end of month" = the last day of the meeting's month.
- "mid-October" = 15 October. "for November" / "end of November" = 30 November.
- "10 Sep", "Oct 3rd", "Wed 16 Sep", "Saturday 10 Oct" = that date. A missing year means the meeting's year, unless that would be more than 6 months before the meeting (then it means next year).
- "from 9 Oct" (a start date) is treated as the due date.
- Anything else (e.g. "before cutover", "before the next review") means **no due date**. Items with no due date are never overdue.

### Owner matching
- Full names come from the attendee lists of **all** notes.
- "Priya N." matches a first name plus last-name initial. "@anita" matches a first name.
- A first name is checked against **this meeting's attendees first**. If exactly one person matches, it's them. If none match (or there's no attendee list), everyone from every note is checked.
- If two people match (e.g. both Priya Nair and Priya Shah were there), the owner becomes **"Priya (ambiguous)"**. We never guess. These items show in `list` but are never emailed. `followup` warns about them.
- "Anita & Rahul" (or "and", ",", "/") gives one item for each person. "Lena (with Priya)" belongs to Lena.
- Everyone, Team, Someone, TBD (and similar) become **unassigned**, never emailed.
- A name that isn't in any attendee list is kept as written.

### Duplicates and status
- Two items are the same if they have the **same owner** and the **same task**, ignoring capitals, punctuation, "the/a/an" and the due-date part. So "send the revised quote to Acme by Friday" and "Send revised quote to Acme - by Friday" are one item.
- Notes are processed from oldest to newest meeting. The item keeps the newest wording, and the **newest stated due date** wins. A later mention without a date keeps the old date.
- A later `[x]` closes an earlier item only when owner and task both match (same rule as above).
- If an item was closed by a note's `[x]` and a **later** meeting lists it as open again, it is reopened.
- `done <id>` (by hand) **always wins**: no later meeting can reopen it, including on re-ingest.
- Re-running `ingest` keeps the same IDs and doesn't create duplicates.

## Files

```
actiontrack.cmd       run this (wraps actiontrack.ps1)
actiontrack.ps1       entry point
lib/Commands.ps1      ingest, list, done, followup
lib/Parser.ps1        reads one note
lib/Dates.ps1         "by Friday" -> a real date
lib/Owners.ps1        "Priya N." -> Priya Nair, or "(ambiguous)"
lib/Store.ps1         data.json, duplicates, done/reopen rules
tests/Run-Tests.ps1   automatic checks
people.example.json   copy to people.json and fill in
notes/                sample meeting notes
```

## Tests

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-Tests.ps1
```

The tests use a temporary data file and a fixed "today" of 2026-10-22.
