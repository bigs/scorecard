# Scorecard TODOs

Running list of ideas and outstanding work, kept in the repo so context survives between sessions.

## In flight
- [ ] **Two display modes — floating panel vs. menu-bar compact.** Add a
      runtime toggle so the same data renders either as the current floating
      Liquid Glass panel or as a menu-bar item that shows the active
      tournament name beside the icon and opens a popover with the top 10 on
      left click. Right-click menu adapts: in floating mode, "Switch to
      Compact"; in compact mode, "Switch to Floating", plus Refresh, Quit,
      and a tournament picker submenu near the top-10 list. Persist the
      chosen mode in `@AppStorage`.

## Backlog
- [ ] **Per-hole scorecard data.** The expanded row currently shows round
      totals only. Hit ESPN's player-event endpoint to render a real
      front-nine/back-nine grid with strokes per hole and color coding for
      eagle/birdie/par/bogey.
- [ ] **Favorites flow polish.** Starring works (right-click menu) but there
      is no UI hint that you can do it; needs a discoverable affordance and
      maybe a quick keyboard shortcut. Verify the starred-section pinning
      renders correctly once a tournament is live.
- [ ] **Cut line readout.** ESPN reports the projected/active cut score on
      `competitions[].notes`; the parser exists but is untested against real
      live data — confirm + surface it visually (a thin row in the list at
      the cut position, or a footer chip).
- [ ] **Better tournament status detail.** When ESPN omits `detail`
      /`shortDetail` (e.g. pre-tournament), fall back to `description` so the
      footer shows something useful ("Scheduled", "Final").
- [ ] **Player headshots.** ESPN provides `headshot.href` per athlete;
      optionally render a small circular image in the row for starred /
      expanded players.
- [ ] **App icon.** Currently empty `AppIcon.appiconset`. Design a flag-
      checker-on-glass icon for the Dock (when active) and the menu bar.
- [ ] **Refresh button affordance.** Visible spinner on the status footer
      while polling, plus a click-to-refresh control somewhere obvious.

## Maybe-someday
- [ ] **Non-golf providers.** Architecture supports it — wire up an
      NFL/NBA/MLB provider behind the same `LeaderboardProvider` protocol
      with a sport-appropriate row layout.
- [ ] **Notifications.** Optional desktop notifications when a starred
      player makes a big move (eagles, leads, dropped shots).
- [ ] **Hover preview of player.** Mouse over a row to show recent shot data
      / strokes-gained breakdown without expanding.
