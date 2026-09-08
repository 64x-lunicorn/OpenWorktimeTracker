# WorkdayManager depends on Clock and DailyLogStore; Workday stays dependency-free

`WorkdayManager` will take a `Clock` protocol (`now: Date`) and a `DailyLogStore`
protocol (file adapter in production, in-memory adapter in tests) through its
`init`, defaulting to production adapters. `Workday` gains no new parameters — it
keeps deriving from the `Date` values `WorkdayManager` passes into its existing
`endingAt:` methods.

We considered injecting the clock into `Workday` directly, and using a bare
closure instead of a protocol. The seam sits on `WorkdayManager` because
`Workday`'s zero-argument derivation is the whole point of an earlier decision —
a caller can't construct one without its Auto Break Rules and Threshold Ladder,
and a clock parameter would be one more thing to forget. The untested surface is
`WorkdayManager`'s orchestration (ticking, autosave, threshold checks), not
`Workday`'s arithmetic. A protocol over a closure gives `Clock` a name and room to
grow — e.g. a schedule method, if the repeating `Timer` ever needs faking too —
without changing call sites again.

So: if `WorkdayManager.tick()` is passing `clock.now` into
`Workday.netWorkTime(endingAt:)`, that's deliberate — the dependency lives one
level up on purpose.

`WorkdayManager` keeps a separately-typed `persistence: PersistenceManager`
property alongside `store: DailyLogStore`, rather than replacing it outright.
`store` defaults to `persistence` itself, so production has one real instance.
The concrete property remains for filesystem settings, folder navigation, and
existing history queries.

The initially deferred editor scope is now owned by `WorkdayManager` too:
editor queries, draft validation, stale-edit merging, acknowledged local writes,
and deletion all cross its interface. Callers no longer delete through the
file adapter and then request a separate reload. Failed mutations leave tracking
and history revisions unchanged and expose an error to the editor. Autosave
remains queued; editor writes wait on that same queue so a successful response
means the local Daily Log was actually written, not that iCloud confirmed it.
Sleep and termination also flush through `DailyLogStore`, including in tests.

The same ownership rule applies to Idle Period sequencing: `WorkdayManager`
receives macOS sleep/wake and lock/unlock events, updates `IdleDetector` first,
and only then evaluates the Workday. Sleep and lock are independent conditions;
both must clear before an Idle Period ends. This replaces observer-order
assumptions and a timed wake delay. A prompt-presenting seam has the existing
panel adapter and a recording test adapter; decisions and window closure share
manager-owned cleanup.
