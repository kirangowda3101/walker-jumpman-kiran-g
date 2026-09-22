#!/usr/bin/env python3
"""
solve.py — measure and verify routes through walker-jumpman using the
tick-accurate simulator in sim.py.

Three modes:

    python3 scripts/solve.py routes
        Fastest possible completion for the high route and the ground route,
        searched separately. Proves each is playable and reports the time cost
        of taking the ground route.

    python3 scripts/solve.py marks
        Derives a jump-mark sequence for godot/tests/route_driver.gd, which
        can only hold the right key. Generated marks are pulled back off
        platform edges so they fire while solidly grounded rather than inside
        the coyote-time window.

    python3 scripts/solve.py check 138 292 424 ...
        Replays a specific mark sequence and reports where it ends up.

Reads the level and tuning files; writes nothing.
"""
import json, os, sys
from collections import deque
import sim

HERE = os.path.dirname(os.path.abspath(__file__))
LEVEL = os.path.join(os.path.dirname(HERE), "godot", "levels", "first_steps.json")

# The high runway. Touching it is what distinguishes the high route from the
# ground route, which has to reach the shelf the long way round instead.
RUNWAY_INDEX = 8


def load():
    lay = json.load(open(LEVEL))
    world = sim.World(lay["solids"], lay["hazards"], lay["fall_y"], lay["width"])
    return lay, world


def key(p, flag):
    return (round(p.x), round(p.y), round(p.vx / 10), round(p.vy / 10),
            p.on_floor, p.consumed,
            min(p.tick - p.last_floor, 8), min(p.tick - p.jump_req, 8), flag)


def clone(p):
    q = sim.Player(p.x, p.y)
    q.vx, q.vy, q.tick = p.vx, p.vy, p.tick
    q.last_floor, q.jump_req = p.last_floor, p.jump_req
    q.consumed, q.on_floor = p.consumed, p.on_floor
    return q


def at_finish(p, finish):
    fx, fy, fw, fh = finish
    return p.x - 9 < fx + fw and p.x + 9 > fx and p.y - 28 < fy + fh and p.y > fy


def on_marker(p, rect):
    x, y, w, h = rect
    return p.on_floor and abs(p.y - y) < 2 and x - 9 <= p.x <= x + w + 9


def search(lay, world, want_high, axes=(1.0, -1.0, 0.0), limit=1500):
    """
    Breadth-first over game states. Every edge costs exactly one tick, so the
    first finish reached is the fastest one. Left and neutral movement are
    included because the ground route has to double back.
    """
    marker = lay["solids"][RUNWAY_INDEX]
    start = sim.Player(*lay["spawn"])
    seen = {key(start, False)}
    queue = deque([(start, False)])
    while queue:
        p, flag = queue.popleft()
        if p.tick > limit:
            continue
        for axis in axes:
            for press in ((False, True) if p.on_floor else (False,)):
                n = clone(p)
                n.step(world, axis, press)
                if world.deadly(n.x, n.y) or n.y > world.fall_y:
                    continue
                f = flag or on_marker(n, marker)
                if at_finish(n, lay["finish"]):
                    if f == want_high:
                        return n.tick
                    continue
                k = key(n, f)
                if k in seen:
                    continue
                seen.add(k)
                queue.append((n, f))
    return None


def replay(lay, world, marks):
    """Drive the level exactly as route_driver.gd does: hold right, jump on marks."""
    p = sim.Player(*lay["spawn"])
    nxt, fired = 0, []
    for _ in range(1500):
        press = nxt < len(marks) and p.x >= marks[nxt] and p.on_floor
        if press:
            fired.append(round(p.x))
            nxt += 1
        p.step(world, 1.0, press)
        if world.deadly(p.x, p.y):
            return ("died on a hazard", p, nxt, fired)
        if p.y > world.fall_y:
            return ("fell", p, nxt, fired)
        if at_finish(p, lay["finish"]):
            return ("finished", p, nxt, fired)
    return ("ran out of ticks", p, nxt, fired)


def derive_marks(lay, world):
    """Find an always-right solution, then pull each mark back off the edge."""
    start = sim.Player(*lay["spawn"])
    seen = {key(start, False)}
    queue = deque([(start, ())])
    raw = None
    while queue and raw is None:
        p, marks = queue.popleft()
        if p.tick > 1400:
            continue
        for press in ((False, True) if p.on_floor else (False,)):
            n = clone(p)
            n.step(world, 1.0, press)
            if world.deadly(n.x, n.y) or n.y > world.fall_y:
                continue
            m = marks + (round(p.x),) if press else marks
            if at_finish(n, lay["finish"]):
                raw = m
                break
            k = key(n, False)
            if k in seen:
                continue
            seen.add(k)
            queue.append((n, m))
    if raw is None:
        return None
    # A mark fired inside the coyote window is tick-exact and fragile: the
    # engine's floor detection differs from the simulator's by a frame or two
    # and the jump is then missed entirely. Pulling each mark back a few pixels
    # makes it fire while the player is unambiguously on a platform.
    for pullback in (0, 5, 10, 15, 20, 25):
        cand = [max(0, x - pullback) for x in raw]
        if replay(lay, world, cand)[0] == "finished":
            return cand
    return list(raw)


def main():
    lay, world = load()
    mode = sys.argv[1] if len(sys.argv) > 1 else "routes"

    if mode == "routes":
        hi = search(lay, world, True)
        lo = search(lay, world, False)
        print(f"level {lay['id']}  width {lay['width']}  finish x={lay['finish'][0]}")
        print(f"  high route:   {hi/60:.2f}s" if hi else "  high route:   IMPOSSIBLE")
        print(f"  ground route: {lo/60:.2f}s" if lo else "  ground route: IMPOSSIBLE")
        if hi and lo:
            print(f"  ground route costs {(lo-hi)/60:+.2f}s with optimal play")
        return 0 if (hi and lo) else 1

    if mode == "marks":
        m = derive_marks(lay, world)
        if not m:
            print("no always-right route exists; the fixture cannot cover this level")
            return 1
        out = replay(lay, world, m)
        print(f"verified: {out[0]} at tick {out[3] and out[1].tick} "
              f"({out[1].tick/60:.2f}s), {out[2]} marks used")
        print()
        print("var jump_marks: Array[float] = [" + ", ".join(f"{x}.0" for x in m) + "]")
        return 0

    if mode == "check":
        marks = [float(a) for a in sys.argv[2:]]
        status, p, used, fired = replay(lay, world, marks)
        print(f"{status} at x={p.x:.0f} y={p.y:.0f} tick={p.tick} "
              f"({p.tick/60:.2f}s), {used}/{len(marks)} marks")
        print(f"jumps actually fired at: {fired}")
        return 0 if status == "finished" else 1

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
