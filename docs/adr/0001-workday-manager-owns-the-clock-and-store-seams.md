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
