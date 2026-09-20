#!/usr/bin/env python3
"""
check_reachability.py — prove the level is completable from the game's own physics.

Reads the movement constants out of godot/features/player/tuning.gd and the
geometry out of godot/levels/first_steps.json, derives the jump envelope from
first principles, and checks every platform-to-platform transition against it.
Then walks the resulting graph from the spawn platform to the finish and
reports whether a route exists.

Reads only. Never writes to the project, never touches the engine.

Usage:
    python3 scripts/check_reachability.py
    python3 scripts/check_reachability.py --jump-velocity 260
    python3 scripts/check_reachability.py --verbose

Exit code 0 if a route exists and no geometry is impossible, 1 otherwise.
"""

import argparse
import json
import math
import os
import re
import sys
from collections import deque

# Player collider, from player.gd::_ready(): RectangleShape2D 18x28 at (0, -14).
PLAYER_W = 18.0
PLAYER_H = 28.0

# A landing is judged safe only if the required distance is inside this
# fraction of the theoretical maximum. The theoretical max assumes a
# frame-perfect jump at full run speed; a human will not hit that every time.
SAFETY = 0.80

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TUNING = os.path.join(ROOT, "godot", "features", "player", "tuning.gd")
LEVEL = os.path.join(ROOT, "godot", "levels", "first_steps.json")


def read_tuning(path):
    """Pull the @export values out of tuning.gd. No Godot needed."""
    text = open(path).read()
    pattern = r"@export\s+var\s+(\w+)\s*:\s*\w+\s*=\s*(-?[\d.]+)"
    values = {name: float(value) for name, value in re.findall(pattern, text)}
    required = ("speed", "jump_velocity", "gravity")
    missing = [key for key in required if key not in values]
    if missing:
        sys.exit(f"tuning.gd is missing: {', '.join(missing)}")
    return values


class Envelope:
    """The reachable region of a single jump, derived from the constants."""

    def __init__(self, speed, jump_velocity, gravity):
        self.speed = speed
        self.v = abs(jump_velocity)
        self.g = gravity
        self.apex = self.v ** 2 / (2.0 * self.g)
        self.airtime = 2.0 * self.v / self.g

    def reach(self, rise):
        """
        Horizontal distance available when landing `rise` px above takeoff.
        Negative rise means landing lower down, which buys more airtime.
        Returns None when the landing is above the apex, i.e. impossible.
        """
        disc = self.v ** 2 - 2.0 * self.g * rise
        if disc < 0:
            return None
        t = (self.v + math.sqrt(disc)) / self.g
        return self.speed * t


def load_platforms(level):
    """Every solid contributes one standable top surface."""
    out = []
    for x, y, w, h in level["solids"]:
        out.append({"x0": float(x), "x1": float(x + w), "top": float(y),
                    "bottom": float(y + h)})
    return out


def headroom(platforms, plat):
    """
    Smallest vertical clearance above a platform's walkable surface.
    A ceiling lower than PLAYER_H means the player cannot stand there —
    which is exactly the bug that made an early version of this level's
    low route physically unenterable.
    """
    worst = float("inf")
    for other in platforms:
        if other is plat:
            continue
        if other["bottom"] <= plat["top"] - 1 and other["x1"] > plat["x0"] and other["x0"] < plat["x1"]:
            worst = min(worst, plat["top"] - other["bottom"])
    return worst


def transitions(platforms, env, fall_y):
    """Every ordered pair of platforms, judged reachable or not."""
    results = []
    for i, a in enumerate(platforms):
        for j, b in enumerate(platforms):
            if i == j:
                continue
            if b["top"] > fall_y:
                continue

            rise = a["top"] - b["top"]          # positive means jumping up

            # Horizontal distance the player must cover, edge to edge.
            if b["x0"] >= a["x1"]:
                gap = b["x0"] - a["x1"]
                direction = "right"
            elif b["x1"] <= a["x0"]:
                gap = a["x0"] - b["x1"]
                direction = "left"
            else:
                gap = 0.0                        # overlapping: straight up or down
                direction = "vertical"

            limit = env.reach(rise)
            if limit is None:
                verdict, margin = "IMPOSSIBLE", None
            else:
                safe = limit * SAFETY
                if gap <= safe:
                    verdict = "PASS"
                elif gap <= limit:
                    verdict = "TIGHT"
                else:
                    verdict = "FAIL"
                margin = (safe - gap) / safe if safe > 0 else 0.0

            results.append({
                "from": i, "to": j, "gap": gap, "rise": rise,
                "limit": limit, "verdict": verdict, "margin": margin,
                "direction": direction,
            })
    return results


def platform_at(platforms, x, y, tol=2.0):
    """Which platform is a point standing on."""
    for i, p in enumerate(platforms):
        if p["x0"] - tol <= x <= p["x1"] + tol and abs(p["top"] - y) <= tol:
            return i
    return None


def route_exists(platforms, edges, start, goal):
    """Breadth-first walk of the passable edges. Returns the path or None."""
    graph = {}
    for e in edges:
        if e["verdict"] in ("PASS", "TIGHT"):
            graph.setdefault(e["from"], []).append(e["to"])
    seen, queue = {start}, deque([(start, [start])])
    while queue:
        node, path = queue.popleft()
        if node == goal:
            return path
        for nxt in graph.get(node, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append((nxt, path + [nxt]))
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jump-velocity", type=float,
                    help="override jump_velocity to see which jumps break")
    ap.add_argument("--speed", type=float, help="override run speed")
    ap.add_argument("--verbose", action="store_true",
                    help="list every reachable transition, not just problems")
    args = ap.parse_args()

    tuning = read_tuning(TUNING)
    level = json.load(open(LEVEL))

    v = args.jump_velocity if args.jump_velocity is not None else tuning["jump_velocity"]
    speed = args.speed if args.speed is not None else tuning["speed"]
    env = Envelope(speed, v, tuning["gravity"])

    print("walker-jumpman reachability check")
    print(f"  level          {level['id']}  width {level['width']}  fall_y {level['fall_y']}")
    print(f"  speed          {speed:.0f} px/s")
    print(f"  jump_velocity  {abs(v):.0f} px/s" +
          ("  [OVERRIDDEN]" if args.jump_velocity is not None else ""))
    print(f"  gravity        {tuning['gravity']:.0f} px/s^2")
    print(f"  -> peak rise   {env.apex:.1f} px")
    print(f"  -> airtime     {env.airtime:.2f} s")
    print(f"  -> flat reach  {env.reach(0):.1f} px   (safe budget {env.reach(0) * SAFETY:.1f})")
    print()

    platforms = load_platforms(level)
    fall_y = float(level["fall_y"])
    problems = []

    # 1. Can the player physically stand on each surface?
    print("headroom")
    for i, p in enumerate(platforms):
        clear = headroom(platforms, p)
        if clear < PLAYER_H:
            print(f"  P{i:<2} x {p['x0']:.0f}-{p['x1']:.0f} top {p['top']:.0f}"
                  f"   clearance {clear:.0f} px  < player height {PLAYER_H:.0f}   BLOCKED")
            problems.append(f"P{i} is unstandable: {clear:.0f}px clearance")
        elif args.verbose:
            shown = "open" if clear == float("inf") else f"{clear:.0f} px"
            print(f"  P{i:<2} x {p['x0']:.0f}-{p['x1']:.0f} top {p['top']:.0f}   clearance {shown}")
    if not problems and not args.verbose:
        print(f"  all {len(platforms)} surfaces clear {PLAYER_H:.0f} px")
    print()

    # 2. Judge every transition against the envelope.
    edges = transitions(platforms, env, fall_y)
    usable = [e for e in edges if e["verdict"] in ("PASS", "TIGHT")]

    print("jumps")
    header = f"  {'from':>4} {'to':>4} {'gap':>7} {'rise':>7} {'limit':>8} {'margin':>8}  verdict"
    print(header)
    shown = 0
    for e in sorted(edges, key=lambda e: (e["from"], e["to"])):
        interesting = e["verdict"] == "TIGHT" or (args.verbose and e["verdict"] in ("PASS", "TIGHT"))
        if not interesting:
            continue
        limit = f"{e['limit']:.0f}" if e["limit"] else "-"
        margin = f"{e['margin'] * 100:.0f}%" if e["margin"] is not None else "-"
        print(f"  P{e['from']:<3} P{e['to']:<3} {e['gap']:7.0f} {e['rise']:7.0f} "
              f"{limit:>8} {margin:>8}  {e['verdict']}")
        shown += 1
    if shown == 0:
        print(f"  {len(usable)} transitions reachable, none inside the tight band")
    print()

    # 3. Is there actually a route from spawn to finish?
    spawn_i = platform_at(platforms, float(level["spawn"][0]), float(level["spawn"][1]))
    fx, fy, fw, fh = level["finish"]
    finish_i = platform_at(platforms, float(fx), float(fy + fh))

    print("route")
    if spawn_i is None:
        print("  spawn is not standing on any platform")
        problems.append("spawn not on a platform")
    elif finish_i is None:
        print("  finish is not resting on any platform")
        problems.append("finish not on a platform")
    else:
        path = route_exists(platforms, edges, spawn_i, finish_i)
        if path:
            print(f"  spawn P{spawn_i} -> finish P{finish_i}")
            print("  " + " -> ".join(f"P{i}" for i in path) + f"   ({len(path) - 1} moves)")
        else:
            print(f"  no route from spawn P{spawn_i} to finish P{finish_i}")
            problems.append("finish unreachable from spawn")
    print()

    if problems:
        print("FAIL")
        for p in problems:
            print(f"  - {p}")
        return 1
    print("PASS  every surface is standable and the finish is reachable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
