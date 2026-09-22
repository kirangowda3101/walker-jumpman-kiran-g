#!/usr/bin/env python3
"""
sim.py — tick-accurate replica of walker-jumpman's movement, used to prove a
layout is playable instead of estimating it with projectile formulas.

Mirrors player.gd::_physics_process step for step at 60 Hz, including the
order of operations (gravity applied before the jump assignment), the 18x28
collider, and axis-separated collision resolution.
"""
import math, json, heapq

DT = 1.0 / 60.0
SPEED, ACCEL, DECEL = 160.0, 1280.0, 1920.0
JUMP_V, GRAV, TERM = -320.0, 960.0, 480.0
COYOTE, BUFFER = 6, 6
PW, PH = 18.0, 28.0


def move_toward(a, b, d):
    return b if abs(b - a) <= d else a + math.copysign(d, b - a)


class World:
    def __init__(self, solids, hazards, fall_y, width):
        self.solids = [(float(x), float(y), float(w), float(h)) for x, y, w, h in solids]
        self.solids.append((float(width), 0.0, 32.0, 430.0))
        self.solids.append((-32.0, 0.0, 32.0, 430.0))
        self.hazards = [(float(x), float(y), float(w), float(h)) for x, y, w, h in hazards]
        self.fall_y = float(fall_y)

    def overlaps(self, px, py):
        l, r, t, b = px - PW / 2, px + PW / 2, py - PH, py
        for (sx, sy, sw, sh) in self.solids:
            if l < sx + sw and r > sx and t < sy + sh and b > sy:
                return (sx, sy, sw, sh)
        return None

    def deadly(self, px, py):
        l, r, t, b = px - PW / 2, px + PW / 2, py - PH, py
        for (hx, hy, hw, hh) in self.hazards:
            # the game builds three triangles across the hazard's width
            step = hw / 3.0
            for i in range(3):
                tx = hx + i * step
                if l < tx + step and r > tx and t < hy + hh and b > hy:
                    return True
        return False


class Player:
    def __init__(self, x, y):
        self.x, self.y = float(x), float(y)
        self.vx = self.vy = 0.0
        self.tick = 0
        self.last_floor = -1000
        self.jump_req = -1000
        self.consumed = False
        self.on_floor = True

    def step(self, world, axis, jump_pressed):
        self.tick += 1
        if self.on_floor and self.vy >= 0.0:
            self.last_floor = self.tick
            self.consumed = False
        if jump_pressed:
            self.jump_req = self.tick
        rate = ACCEL if axis != 0 else DECEL
        self.vx = move_toward(self.vx, axis * SPEED, rate * DT)
        self.vy = min(self.vy + GRAV * DT, TERM)
        if (not self.consumed and self.tick - self.last_floor <= COYOTE
                and self.tick - self.jump_req <= BUFFER):
            self.vy = JUMP_V
            self.consumed = True
            self.jump_req = -1000

        # horizontal, then vertical, each resolved on its own axis
        self.x += self.vx * DT
        hit = world.overlaps(self.x, self.y)
        if hit:
            sx, sy, sw, sh = hit
            self.x = sx - PW / 2 if self.vx > 0 else sx + sw + PW / 2
            self.vx = 0.0

        self.y += self.vy * DT
        self.on_floor = False
        hit = world.overlaps(self.x, self.y)
        if hit:
            sx, sy, sw, sh = hit
            if self.vy > 0:
                self.y = sy
                self.on_floor = True
            else:
                self.y = sy + sh + PH
            self.vy = 0.0
        else:
            probe = world.overlaps(self.x, self.y + 1.0)
            if probe and self.vy >= 0:
                self.on_floor = True
        self.x = max(self.x, 10.0)


def run(world, spawn, jump_xs, limit=2000):
    """Hold right; press jump the first tick x passes each trigger while grounded."""
    p = Player(*spawn)
    nxt = 0
    for _ in range(limit):
        press = False
        if nxt < len(jump_xs) and p.x >= jump_xs[nxt] and p.on_floor:
            press = True
            nxt += 1
        p.step(world, 1.0, press)
        if world.deadly(p.x, p.y):
            return ("dead-hazard", p.x, p.y, p.tick, nxt)
        if p.y > world.fall_y:
            return ("dead-fall", p.x, p.y, p.tick, nxt)
        if p.x >= FINISH_X:
            return ("finish", p.x, p.y, p.tick, nxt)
    return ("timeout", p.x, p.y, p.tick, nxt)
