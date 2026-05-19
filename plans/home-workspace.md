# Home Workspace — A Place You Visit

## What this is

A long-form design exploration of what workspace 10 (the `⌂` workspace,
toggled via Super+0 / Super+D) could become. Not an implementation plan yet —
the philosophical framing comes first because it shapes every later choice.

Today the home workspace is a single ghostty pinned via `[workspace 10 silent]`
(`home.nix:125`). The `ws-redirect.sh` script keeps non-dashboard windows out.
That's the seed; this doc is what we could grow.

---

## Framing — what makes a home workspace different

Most desktops are inert wallpaper that holds icons. Launchers are reactive
surfaces you summon and dismiss. Dashboards are passive info displays.
**None of them are what the computer *is* to you.**

A home workspace, done well, can be **the persistent surface where your
relationship with your machine lives.** That framing unlocks design choices
nothing else gets to make:

- **Spatial memory matters.** Things stay where you put them. Forever. Brain
  wires "agenda is top-left, scratchpad is bottom-right" as muscle memory.
  This is what makes a physical desk feel like *home* and a desktop OS feel
  like *somewhere you visit*.
- **Time horizons can be long.** Apps optimize for the session. A home
  workspace can optimize for the year. Habit dots that accumulate. A bonsai
  that grows for months. A journal that builds.
- **It can be the only thing that knows everything about you.** Browser knows
  URLs, terminal knows commands, calendar knows meetings. Home workspace can
  be the membrane all of it passes through.

## The center of gravity (chosen)

Not productivity. **Calm + alive + remembers you.** A *room* in your computer,
not a dashboard.

One-line shape: **a place you visit, that remembers you, that's alive in small
ways, with a quiet assistant in the corner.**

---

## The wallpaper IS the surface

The travel photos are not background — they are the *world*. Once widgets stop
competing with the photo and start being *inhabitants of it*, the design
collapses into something coherent:

- The photo is a place.
- Things live in that place.
- You visit that place.

The existing wallpaper-derived dynamic theming already makes overlay UI feel
native to whatever photo is up. That work isn't decoration; it's load-bearing
for this whole concept.

---

## Confirmed direction

- **One living thing + productivity citizens**, where the productivity
  citizens are **faded until you make contact with the machine.** Otherwise
  the workspace belongs to the living thing.
- **Eventually**: auto-flip to home workspace after some idle period (idle
  screen behavior via `hypridle`). Deferred — see "Skipped for now."
- **AI is a different citizen, not the main thing.** The persistent terminal
  becomes the AI corner: a resident, not a roommate. Summonable, watches the
  day, has access to scratchpad + calendar + code, doesn't interrupt.

## Skipped for now (revisit later)

- **State machine** for active/ambient/idle/lock transitions. Conceptually the
  skeleton everything hangs off, but deferred until the core ideas are felt
  out.
- **Time-of-day overlays** on the photo (warm morning / blue hour / star
  field). Rejected — user doesn't want it.
- **Weather mirroring reality** on the photo. On hold.
- **Activity-driven blooms** (commit → flower in the photo). On hold.

## The four already-loved citizens

These are the productivity inhabitants — they sit faded around the edges of
the photo and come alive when you engage with the machine:

1. **Calendar / agenda** — synced to Google Calendar. Today's view.
2. **Permanent terminal** — eventually an AI-focused resident, not a generic
   shell. Watches the day, has standing access to scratchpad / calendar / code.
3. **Quick task inbox** — one-line input that appends timestamped lines to a
   todo file. Distinct from the scratchpad: structured, dated, reviewable.
4. **Scratchpad** — single file, auto-saves, also accessible from CLI so it's
   never trapped on the workspace.

Eventually we want a small **simulation** somewhere too, but it's deferred
behind picking the living thing first.

---

## The living thing — open decision

The remaining open creative choice. We're picking *one* — these archetypes
don't combine well.

### Qualities that separate "alive" from "animated"

- **Variable rhythm** — sometimes still, sometimes moving. Not metronomic.
- **Absence** — sometimes it's not there at all. Presence has to be earned.
- **Notices things** — pauses, looks, reacts to mouse, reacts to wind/time.
- **Continuity** — same one tomorrow as today. Has a history with you.
- **Restraint** — does less than it could. Magic is in what it *doesn't* do.

Most ambient creatures in software fail by being always on, always animating,
always cute. The target is closer to *a cat in another room* than a Tamagotchi
on screen.

### Archetypes considered

1. **The Wisp** — single soft mote of light drifting through the photo.
   Flickers, pauses near things, fades for an hour. At dusk occasionally
   multiplies into a small flock. Universal (works on any photo), cheap,
   mystical. Low character — you witness it, you don't relate to it.

2. **The Wanderer** ⭐ (claude's pick) — tiny silhouetted figure (distant
   backpacker / walking shape) moving slowly across the foreground over the
   course of the day. Stops at things. Sits sometimes. Disappears at night,
   returns at dawn from a different edge. Thematically perfect for *travel*
   photos — the wanderer is the spirit of travel, or past-you returning.
   Renders trivially (vector silhouette). High character despite low fidelity.
   Needs the photo to have walkable ground (~95% of landscape photos qualify).

3. **The Resident Creature** — small bird / fox / cat / etc that inhabits the
   photo. Lands, perches, looks, leaves. Has a territory inside the photo.
   Sleep cycle. Potentially different creature per photo (gull at beaches,
   sparrow at cities, fox at forests — "spirit of place"). Highest character,
   highest cost (sprite animation, pathing, photo-content awareness). Real
   risk of being twee — line between "cat in a window" and "Clippy" is real.

4. **The Flock** — boids. Birds, fireflies, leaves. Beautiful collective
   motion, no individuals to relate to. Pure ambient. Trade-off: doesn't make
   the workspace feel like *home*. Feels like a screensaver.

5. **The Patient Grower** — moss / vines / lichen that grows on the photo over
   weeks. Long timescale, gorgeous, most respectful of the photo. Not really
   a being though — it's decor that changes.

### Claude's read

The two real contenders are **the Wanderer** and **the Resident Creature**.
Wisp/Flock are too impersonal for the "comes home to it, missed when away"
goal. Patient Grower is decor not companion.

- **Wanderer** is the more elegant idea. Cheap, high meaning per pixel, never
  feels twee because it's a silhouette. Gets *better* the longer you have it
  — accumulates the implication of having walked all those places.
- **Resident Creature** is the more intimate idea. Real attachment. But
  implementation cost and twee-risk are real.

### Open questions to narrow it

When we come back to this, these four questions resolve the choice:

1. Do you want to **relate to it** (bond, miss it, name it) or **witness it**
   (atmospheric, no personality)?
2. Should it ever **respond to you** — mouse, typing, activity — or stay
   indifferent to the machine?
3. What timescale feels right: **minutes** (drifts visibly), **hours** (you
   notice it moved), or **days** (you check on it like a plant)?
4. Should it **persist across wallpaper changes** (migrates with you to the
   new photo, accumulating history) or **belong to the photo** (different one
   per place)?

---

## Implementation order (sketch — not committed)

When we resume:

1. Pick the living thing (answer the four questions above).
2. Get a minimum-viable version of it rendering on top of the wallpaper.
   Likely a layer-shell overlay (quickshell or a small wgpu/Qt thing) sitting
   above the wallpaper but below windows.
3. Wire the four productivity citizens, designed *around* the photo with
   fade-on-idle behavior. Reuses the dynamic theming pipeline.
4. **Then** revisit the state machine (active / ambient / idle / lock) and
   `hypridle` integration so the fade behavior is real instead of just on/off.
5. **Much later** — the sim, activity-driven photo accents, weather mirroring,
   cross-device mirroring, memory prosthetic via AI terminal.

---

## Provocations worth re-reading when we resume

1. **What is your home workspace *for*?** Apps answer this trivially (Spotify
   = music). Home workspace can be for *anything*, which means it must be
   designed around a posture, not a feature list. Picked: calm + alive +
   remembers you.
2. **What can only exist here?** The killer use cases will be ones that don't
   make sense as an app — too small to launch, too persistent to dismiss, too
   personal to package.
3. **What rituals do you want?** Design backward from the daily/weekly/yearly
   moments. "When I sit down in the morning I want X."
4. **What would feel like *home*?** Not productive. Not impressive. *Home*.
   Warm corners, things that have been there a while, slightly worn, smells
   right.
