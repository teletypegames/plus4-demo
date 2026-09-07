; -----------------------------------------------------------
; main.asm - Plus/4 demo: the Teletype Games title card
;   a colour wash runs across the title, the prompt blinks,
;   any key returns to BASIC
;   all timed by polling the TED raster beam
;
; Build: acme -f cbm -o plus4-demo.prg main.asm
; Run:   xplus4 plus4-demo.prg
; -----------------------------------------------------------

!cpu 6502
!to "plus4-demo.prg", cbm

; ---- TED registers ----
TED_BG    = $ff15        ; background colour
TED_BORD  = $ff19        ; border colour
TED_RASTL = $ff1d        ; raster line, low 8 bits
TED_KBD   = $ff08        ; keyboard row latch (write: latch, read: rows)
KBD_COLS  = $fd30        ; keyboard column select (0 = selected)

SCREEN  = $0c00          ; screen RAM (40x25 chars)
COLRAM  = $0800          ; colour RAM: luminance << 4 | hue

CHROUT  = $ffd2          ; KERNAL: print a character

; ---- colours (luminance in the high nibble) ----
BLACK     = $00
DARK_BLUE = $16
CYAN      = $53
WHITE     = $71
GOLD      = $47
SYNC_LINE = $cc          ; raster line the frame loop waits for

; ---- layout ----
TITLE_ROW  = 8
TITLE_COL  = 13
PROMPT_ROW = 20
PROMPT_COL = 13

; print a fixed text with one colour
!macro prtext .row, .col, .color, .src, .len {
    ldx #0
-   lda .src, x
    sta SCREEN + .row * 40 + .col, x
    lda #.color
    sta COLRAM + .row * 40 + .col, x
    inx
    cpx #.len
    bne -
}

* = $1001

; ---- BASIC stub: 10 SYS 4109 ----
; so after LOAD"*",8,1 it's enough to type RUN
!byte $0b, $10           ; address of next line
!byte $0a, $00           ; line number: 10
!byte $9e                ; SYS token
!text "4109"             ; = $100d
!byte $00                ; end of line
!byte $00, $00           ; end of program

start:                   ; = $100d
    lda #$93             ; clear the screen through the KERNAL: this also
    jsr CHROUT           ;   parks the cursor before the IRQ is stopped
    sei                  ; no KERNAL IRQ - raster polling must not jitter

    lda TED_BG
    sta saved_bg
    lda TED_BORD
    sta saved_bord
    lda #DARK_BLUE
    sta TED_BG
    lda #BLACK
    sta TED_BORD

    +prtext TITLE_ROW,  TITLE_COL,  WHITE, txt_title,  TITLE_LEN
    +prtext 10,         14,         CYAN,  txt_sub,    SUB_LEN
    +prtext 14,          8,         GOLD,  txt_line1,  LINE1_LEN
    +prtext 15,          6,         GOLD,  txt_line2,  LINE2_LEN
    +prtext PROMPT_ROW, PROMPT_COL, WHITE, txt_prompt, PROMPT_LEN

    lda #0
    sta framectr

-   jsr check_key        ; the RETURN that started us may still be down
    bne -

; ============================================================
; main loop - one pass per frame
; ============================================================
main:
    jsr wait_frame
    inc framectr

    ; colour wash: the ramp slides one cell every second frame
    lda framectr
    lsr
    sta wash_base
    ldx #0
-   txa
    clc
    adc wash_base
    and #$0f
    tay
    lda ramp, y
    sta COLRAM + TITLE_ROW * 40 + TITLE_COL, x
    inx
    cpx #TITLE_LEN
    bne -

    ; blinking prompt: hidden while bit 5 of the frame counter is set
    lda framectr
    and #$20
    beq +
    lda #DARK_BLUE
    bne ++
+   lda #WHITE
++  ldx #0
-   sta COLRAM + PROMPT_ROW * 40 + PROMPT_COL, x
    inx
    cpx #PROMPT_LEN
    bne -

    jsr check_key
    beq main

; ---- back to BASIC ----
    lda saved_bg
    sta TED_BG
    lda saved_bord
    sta TED_BORD
    cli
    lda #$93
    jsr CHROUT
    rts

; ============================================================
; wait_frame - wait for the raster beam to pass SYNC_LINE once
; ============================================================
wait_frame:
-   lda TED_RASTL
    cmp #SYNC_LINE
    bne -
-   lda TED_RASTL
    cmp #SYNC_LINE
    beq -
    rts

; ============================================================
; check_key - Z set when no key is pressed
;   all columns selected, joysticks deselected, rows latched
; ============================================================
check_key:
    lda #$00
    sta KBD_COLS
    lda #$ff
    sta TED_KBD
    lda TED_KBD
    cmp #$ff
    rts

; ============================================================
; data
; ============================================================
ramp:                    ; gold rising to white and back, 16 steps
    !byte $17, $27, $37, $47, $57, $67, $77, $71
    !byte $71, $77, $67, $57, $47, $37, $27, $17

txt_title:  !scr "teletype games"
TITLE_LEN  = * - txt_title
txt_sub:    !scr "plus/4 demo"
SUB_LEN    = * - txt_sub
txt_line1:  !scr "6502 assembly with acme"
LINE1_LEN  = * - txt_line1
txt_line2:  !scr "released through warpengine"
LINE2_LEN  = * - txt_line2
txt_prompt: !scr "press any key"
PROMPT_LEN = * - txt_prompt

framectr:   !byte 0
wash_base:  !byte 0
saved_bg:   !byte 0
saved_bord: !byte 0
