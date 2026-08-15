# Context

OpenWorktimeTracker is a macOS menu bar app that automatically tracks how long you
work each day, so you don't have to remember to start or stop a timer.

## Language

**Workday**:
One person's tracked time for a single calendar date. It begins when the Mac is
first used that day and is either running, paused, or ended.
_Avoid_: Session, shift, day entry

**Gross Time**:
Wall-clock time from the start of the workday to now (or to its end), before
anything is deducted.
_Avoid_: Total time, elapsed time

**Pause**:
Time deliberately not counted as work — either because the user pressed pause or
because an idle period was judged to be a break.
_Avoid_: Break, stop

**Auto Break**:
Rest time the law requires but the user never took. Deducted automatically once
work passes a legal threshold, and only for the part not already covered by a Pause.
_Avoid_: Legal break, mandatory break, ArbZG break

**Net Work Time**:
The number that matters: Gross Time minus every Pause and any Auto Break. This is
what the menu bar shows.
_Avoid_: Actual time, real time, worked hours

**Idle Period**:
A stretch with no keyboard or mouse activity, or with the screen locked. It is not
counted either way until the user decides.
_Avoid_: Inactivity, away time

**Idle Decision**:
The user's answer about one Idle Period — either _work_ (a meeting, thinking) or
_pause_ (a break). Recorded on the workday so the same question is never asked twice.
_Avoid_: Idle choice, resolution

**Threshold**:
A configurable point in the day that triggers a notification and recolours the menu
bar — for example 8 hours as normal and 10 hours as critical.
_Avoid_: Limit, alarm

**Daily Log**:
The one JSON file per calendar date holding that day's workday, readable and
exportable by hand.
_Avoid_: Record, database entry, log file
