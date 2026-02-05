# Cyberpunk Breach Protocol - Game Rules

## Overview

Breach Protocol is a hacking minigame inspired by Cyberpunk 2077. Players must navigate a grid of hex codes to complete target sequences within a limited number of moves.

---

## Core Mechanics

### 1. Code Matrix Grid

- A **5x5 or 6x6 grid** of two-character hexadecimal codes
- Common codes: `1C`, `BD`, `55`, `E9`, `7A`, `FF`
- Each cell can only be selected **once** per game

### 2. Buffer (Move Limit)

- The buffer represents your **limited number of selections** (typically 4-8 moves)
- Each cell selection consumes **one buffer slot**
- The game ends when the buffer is completely filled
- Plan your moves carefully - every selection counts!

### 3. Alternating Row/Column Selection

This is the **core mechanic** that makes the game strategic:

| Move | Constraint | Direction |
|------|------------|-----------|
| 1 | TOP ROW only | Horizontal |
| 2 | Column of previous selection | Vertical |
| 3 | Row of previous selection | Horizontal |
| 4 | Column of previous selection | Vertical |
| ... | Pattern continues | H → V → H → V... |

**Key Rules:**
- **First move**: Must select from the **top row** (row 0)
- **Subsequent moves**: Alternate between column and row constraints
- You can only select from cells in the **current constraint line**
- Previously selected cells are **blocked** and cannot be reselected

### 4. Target Sequences

- **1 to 3 target sequences** to complete (e.g., `1C 55 BD`)
- Sequences must be entered in **exact order** within your buffer
- Sequences do **not** need to be consecutive in the buffer
- Multiple sequences can **overlap** and share codes
- Completing more sequences = higher rewards

**Example:**
- Target: `1C 55 BD`
- Buffer: `7A 1C E9 55 BD` ✓ (Contains `1C`, then `55`, then `BD` in order)
- Buffer: `1C BD 55` ✗ (Wrong order)

### 5. Timer

- The timer **starts AFTER your first selection**
- Use this to your advantage: **plan your path before clicking!**
- Study the grid and map out your route while the timer is paused

### 6. Win/Lose Conditions

**Win:**
- Complete **at least one** target sequence before the buffer fills

**Lose:**
- Buffer is **full** with no sequences completed
- Timer **expires** with no sequences completed

---

## Strategy Tips

1. **Plan before clicking** - The timer doesn't start until your first move
2. **Look for overlaps** - Completing multiple sequences with shared codes is efficient
3. **Map your path visually** - Trace the horizontal/vertical pattern before committing
4. **Prioritize valuable sequences** - If you can't get all, focus on the best reward
5. **Watch the buffer** - Don't waste moves on codes you don't need

---

## Difficulty Variations

| Difficulty | Grid Size | Buffer Size | Sequences | Timer |
|------------|-----------|-------------|-----------|-------|
| Easy | 5x5 | 6-8 | 1 | 60s |
| Medium | 5x5 | 5-6 | 2 | 45s |
| Hard | 6x6 | 4-5 | 3 | 30s |

---

## Visual Reference

```
    0    1    2    3    4     <- Column indices
  ┌────┬────┬────┬────┬────┐
0 │ 1C │ BD │ 55 │ E9 │ 7A │  <- First move: select from this row only
  ├────┼────┼────┼────┼────┤
1 │ 55 │ 1C │ 7A │ BD │ FF │
  ├────┼────┼────┼────┼────┤
2 │ E9 │ FF │ BD │ 1C │ 55 │
  ├────┼────┼────┼────┼────┤
3 │ 7A │ 55 │ 1C │ FF │ E9 │
  ├────┼────┼────┼────┼────┤
4 │ BD │ E9 │ FF │ 55 │ 1C │
  └────┴────┴────┴────┴────┘

Buffer: [  ] [  ] [  ] [  ] [  ] [  ]
Target: 1C → 55 → BD
```
