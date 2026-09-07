# Plus/4 Demo — Teletype Games title card

A Commodore Plus/4 program written in 6502 assembly (built with the ACME assembler): the smallest complete example of a Plus/4 title that goes through the Teletype Games build pipeline. It clears the screen, paints the Teletype Games title card, runs a gold colour wash across the title in sync with the raster beam, blinks a prompt, and hands control back to BASIC on any key.

The Plus/4 sibling of the [C64 demo](https://git.teletypegames.org/games/c64-demo): same assembler, same Makefile, same pipeline shape — only the machine differs.

## Controls

| Key | Action |
|-----|--------|
| any key | return to BASIC (colours restored, screen cleared) |

Keys are read straight from the keyboard latch (`$FD30` / `$FF08`), the KERNAL IRQ is switched off while the demo runs.

## Build and run

```sh
make build       # produce plus4-demo.prg
make run         # build + launch in VICE (xplus4)
make rebuildrun  # clean rebuild + run
make deps        # on macOS: install acme + vice via Homebrew
```

Loading the `.prg` on a real or emulated Plus/4:

```
LOAD"*",8,1
RUN
```

Headless smoke test with VICE (runs for a few emulated seconds, then writes a screenshot):

```sh
xplus4 +sound -warp -limitcycles 30000000 -exitscreenshot shot.png -autostartprgmode 1 plus4-demo.prg
```

## How it works

- **BASIC stub** at `$1001`: `10 SYS 4109`, so `RUN` starts the code at `$100D`.
- **Screen** is written directly: screen RAM at `$0C00`, colour RAM at `$0800`. A Plus/4 colour byte is `luminance << 4 | hue`, which is what the wash exploits — the same gold hue at eight luminances, peaking in white.
- **Timing**: no interrupts; the main loop polls the TED raster register (`$FF1D`) and does one pass per frame.
- **Text**: the `+prtext` macro copies a fixed screen-code string to a row/column with one colour. Strings are written in lowercase ASCII, which ACME's `!scr` maps to the uppercase screen codes of the default character set.
- **Exit**: the saved border and background colours are restored, interrupts re-enabled, and the screen cleared through the KERNAL (`$FFD2`) before `RTS` returns to BASIC.

## Memory map

```
$1001 .. $100C   BASIC stub (10 SYS 4109)
$100D .. ...     machine code + texts + variables
$0C00 .. $0FE7   screen RAM (written directly)
$0800 .. $0BE7   colour RAM
$FF15 / $FF19    background / border colour (TED)
$FF1D            raster line (frame sync)
$FD30 / $FF08    keyboard column select / row latch
```

## Pipeline

`.woodpecker.yaml` is a one-line marker (`platform: plus4`); the pipeline itself is served by the update server. See [plus4-build](https://git.teletypegames.org/build/plus4-build) for the toolchain and the platform page on the wiki: https://wiki.teletypegames.org/development/plus4
