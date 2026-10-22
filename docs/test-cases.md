# actiontrack: Test Cases

| | |
|---|---|
| Version | 1.0 |
| Date | 22 October 2026 |
| Test data | The 36 files in `notes/` |
| "Today" for all tests | 2026-10-22 |
| Last result | **65 of 65 automated checks passed** |

## How to run

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Run-Tests.ps1
```

The script uses a temporary data file, so it never touches your real
`data.json`. "Auto" in the tables below means the case is checked by this
script; "Manual" means a person checks it by running the command. The 63
"Auto" cases below cover all 65 checks: TC-S04 and TC-S07 also check that the
repeat ingest itself succeeds.

Requirement IDs (FR, EC, NFR) refer to `docs/requirements-specification.md`.

## 1. Due-date resolution

Meeting dates: 2026-09-01 is a Tuesday, 2026-10-05 a Monday.

| ID | Input (task text, meeting date) | Expected due date | Req | Type |
|---|---|---|---|---|
| TC-D01 | "send the quote by Friday", 2026-09-01 | 2026-09-04 | FR-1.6 | Auto |
| TC-D02 | "x by Friday", meeting on Friday 2026-09-04 | 2026-09-11 (next week) | FR-1.6 | Auto |
| TC-D03 | "x by tomorrow", 2026-09-01 | 2026-09-02 | FR-1.6 | Auto |
| TC-D04 | "write the postmortem by EOD tomorrow", 2026-09-21 | 2026-09-22 | FR-1.6 | Auto |
| TC-D05 | "x by EOD", 2026-10-08 | 2026-10-08 | FR-1.6 | Auto |
| TC-D06 | "draft plan by end of next week", 2026-09-03 | 2026-09-11 | FR-1.6 | Auto |
| TC-D07 | "collect quotes by end of month", 2026-09-14 | 2026-09-30 | FR-1.6 | Auto |
| TC-D08 | "start SSO spike by next Tuesday", 2026-10-05 | 2026-10-13 | FR-1.6 | Auto |
| TC-D09 | "finalise targets by Oct 3rd", 2026-09-30 | 2026-10-03 | FR-1.6 | Auto |
| TC-D10 | "export invoices by 10 Sep", 2026-09-03 | 2026-09-10 | FR-1.6 | Auto |
| TC-D11 | "finalise copy by Wed 16 Sep", 2026-09-14 | 2026-09-16 | FR-1.6 | Auto |
| TC-D12 | "schedule cutover for Saturday 10 Oct", 2026-09-29 | 2026-10-10 | FR-1.6 | Auto |
| TC-D13 | "propose rotation by mid-October", 2026-09-30 | 2026-10-15 | FR-1.6 | Auto |
| TC-D14 | "schedule the QBR for November", 2026-10-14 | 2026-11-30 | FR-1.6 | Auto |
| TC-D15 | "run the customer survey, results due 15 October" | 2026-10-15; task "run the customer survey" | FR-1.6 | Auto |
| TC-D16 | "freeze edits from 9 Oct", 2026-09-29 | 2026-10-09 | FR-1.6 | Auto |
| TC-D17 | "cut costs by 10% - proposal by 2026-10-09" | 2026-10-09 ("10%" is not a date) | FR-1.6 | Auto |
| TC-D18 | "send revised quote to Acme - by Friday", 2026-09-08 | 2026-09-11; dash removed from task | FR-1.6 | Auto |
| TC-D19 | "circulate the summary tomorrow" (no "by"), 2026-09-30 | 2026-10-01 | FR-1.6 | Auto |
| TC-D20 | "snapshot the DB before cutover" | No due date | EC-4 | Auto |
| TC-D21 | "x by 5 Jan", 2026-12-20 | 2027-01-05 (year rolls over) | FR-1.6 | Auto |
| TC-D22 | Meeting date "Monday, 14 September 2026" | 2026-09-14 | FR-1.2 | Auto |
| TC-D23 | Meeting date "sometime last week" | Not understood | EC-7 | Auto |

## 2. Owner matching

| ID | Input (name, attendees) | Expected owner | Req | Type |
|---|---|---|---|---|
| TC-O01 | "Priya N.", both Priyas present | Priya Nair | FR-1.7 | Auto |
| TC-O02 | "Priya", both Priyas present | Priya (ambiguous) | EC-5 | Auto |
| TC-O03 | "Rahul", only Rahul Mehta present | Rahul Mehta | FR-1.7 | Auto |
| TC-O04 | "Rahul", no attendee list, two Rahuls known | Rahul (ambiguous) | EC-5 | Auto |
| TC-O05 | "@anita" | Anita Desai | FR-1.7 | Auto |
| TC-O06 | "Everyone" | unassigned | EC-3 | Auto |
| TC-O07 | "Anita & Rahul" | Two owners: Anita, Rahul | FR-1.7 | Auto |
| TC-O08 | "Lena (with Priya)" | Lena | FR-1.7 | Auto |
| TC-O09 | "Send revised quote to Acme." vs "send the revised quote to Acme" | Same task key | FR-1.8 | Auto |

## 3. Ingest on the sample notes

| ID | Scenario | Expected result | Req | Type |
|---|---|---|---|---|
| TC-I01 | `ingest notes` | Exit code 0 (on screen: 32 notes read, 95 items) | FR-1 | Auto |
| TC-I02 | Same quote item in 3 meetings | Stored once | EC-1 | Auto |
| TC-I03 | Quote item ticked `[x]` on 2026-09-15 | Status done | EC-2 | Auto |
| TC-I04 | Wireframes item repeated with new due date | Due date 2026-09-24 (newest wins) | EC-1 | Auto |
| TC-I05 | Quoted line "> - [ ] Karan to refund ... by Friday" | Ignored; refund item has no due date | FR-1.4 | Auto |
| TC-I06 | Task lines in a code block and an HTML comment | Not stored | FR-1.4 | Auto |
| TC-I07 | "Priya to sign off..." with both Priyas present | Stored as Priya (ambiguous) | EC-5 | Auto |
| TC-I08 | Table row (Owner / Action / Due) | Stored for Anita Desai | FR-1.3 | Auto |
| TC-I09 | `ACTION: Karan to circulate ...` line | Stored for Karan Joshi | FR-1.3 | Auto |
| TC-I10 | Note dated "sometime last week" | Uses file-name date; item stored | EC-7 | Auto |
| TC-I11 | Empty file, binary file, file with no date | Skipped with a reason; no crash | EC-6 | Manual (see `docs/sample-output.md`) |
| TC-I12 | `.txt` file in the folder | Reported as ignored | FR-1.1 | Manual |
| TC-I13 | `ingest nope` (missing folder) | "folder not found", exit code 1 | EC-8 | Manual |

## 4. Status, done and assign

| ID | Scenario | Expected result | Req | Type |
|---|---|---|---|---|
| TC-S01 | Item due 2026-10-02, today 2026-10-22 | Overdue | FR-2.4 | Auto |
| TC-S02 | Same item, today 2026-10-01 | Not overdue | FR-2.4 | Auto |
| TC-S03 | `done <id>` | Exit code 0 | FR-3.1 | Auto |
| TC-S04 | Re-ingest after `done` | Item count unchanged | FR-1.9 | Auto |
| TC-S05 | Re-ingest after `done` | Item still done (by hand) | FR-3.2 | Auto |
| TC-S06 | `assign <id> "Priya Shah"` on an ambiguous item | Exit code 0 | FR-4.1 | Auto |
| TC-S07 | Re-ingest after `assign` | Item keeps Priya Shah | FR-4.3 | Auto |
| TC-S08 | Re-ingest after `assign` | No new "(ambiguous)" copy | FR-4.3 | Auto |
| TC-S09 | Re-ingest after `assign` | Item count unchanged | FR-4.3 | Auto |
| TC-S10 | `assign <id> Priya` | Refused (ambiguous), exit code 1 | FR-4.2 | Auto |
| TC-S11 | `assign <id> "Nobody Here"` | Refused (unknown), exit code 1 | FR-4.2 | Auto |
| TC-S12 | `done 9999` | "no item with id 9999", exit code 1 | EC-8 | Auto |

## 5. List

| ID | Scenario | Expected result | Req | Type |
|---|---|---|---|---|
| TC-L01 | `list --status late` | Error, exit code 1 | EC-8 | Auto |
| TC-L02 | `list --today tomorrow` | Error, exit code 1 | EC-8 | Auto |
| TC-L03 | `list --status overdue` | Only overdue items; rows red with `OVERDUE` | FR-2.3 | Manual |
| TC-L04 | `list --owner "Priya Nair"` | Only Priya Nair's items | FR-2.2 | Manual |
| TC-L05 | `list --due-before 2026-09-10 --status overdue` | 4 items, all due before 10 Sep | FR-2.2 | Manual |

## 6. Follow-up email

| ID | Scenario | Expected result | Req | Type |
|---|---|---|---|---|
| TC-F01 | `followup Priya` | Refused: matches two people; exit code 1 | EC-5 | Auto |
| TC-F02 | `followup "Priya Nair" --dry-run` | Exit code 0 | FR-5.3 | Auto |
| TC-F03 | After the dry run | No `drafts/` folder created | FR-5.3 | Auto |
| TC-F04 | `followup "priya nair"` with `people.json` | Exit code 0 | FR-5.2 | Auto |
| TC-F05 | Draft file | `to` = address from `people.json` | FR-5.4 | Auto |
| TC-F06 | Draft body | Lists open item "Collect beta feedback from Acme" | FR-5.1 | Auto |
| TC-F07 | Draft body | Does not list items already done | FR-5.1 | Auto |
| TC-F08 | No `people.json` | Warning shown; `to` empty | FR-5.4 | Manual |
| TC-F09 | Claude Code creates the Gmail draft | Draft appears in Gmail Drafts; nothing is sent | FR-5.5 | Manual (done 22 Oct 2026) |
| TC-F10 | Claude Code tries a Gmail send, reply or forward tool | Blocked by `.claude/settings.json` | FR-5.5 | Manual |

## 7. Repository rules

| ID | Check | Expected result | Req | Type |
|---|---|---|---|---|
| TC-R01 | `git check-ignore data.json people.json drafts/x.json` | All three ignored | NFR-3 | Manual |
| TC-R02 | Search the repository for email addresses | Only `example.com` addresses | NFR-4 | Manual |
