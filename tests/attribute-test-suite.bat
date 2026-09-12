; ============================================================
; ATTRIBUTES
;
; attron and attroff take any number of attributes, each an A_* symbol or
; an integer, and OR them together.  Whether an attribute took is checked
; the only way it can be from CLIPS: write a character with it on, read
; the cell back with inch, and look at the attribute bits.
;
; Two names the wrapper knows are left out.  A_NORMAL is zero, and the
; wrapper takes zero for "not an attribute" and refuses it.  A_ITALIC is
; bit 31, which does not fit the int the wrapper collects attributes in,
; so it is refused too.  Neither is asserted either way here.
; ============================================================

(fresh-screen)

; what a cell written right now looks like
(deffunction attr-cell-attributes ()
  (ncurses-move 10 10)
  (ncurses-addch 65)
  (ncurses-move 10 10)
  (ncurses-chtype-attributes (ncurses-inch)))

(expect "with nothing on, a cell has no attributes" 0 (attr-cell-attributes))

; ------------------------------------------------------------
; one at a time, on and off
; ------------------------------------------------------------

(defglobal
  ?*at-a* = 0
  ?*at-b* = 0)

(expect "attron A_BOLD" OK (ncurses-attron A_BOLD))
(bind ?*at-a* (attr-cell-attributes))
(expect-true "bold is on the cell" (<> 0 ?*at-a*))
(expect "attroff A_BOLD" OK (ncurses-attroff A_BOLD))
(expect "and off the next cell" 0 (attr-cell-attributes))

(expect "attron A_UNDERLINE" OK (ncurses-attron A_UNDERLINE))
(bind ?*at-b* (attr-cell-attributes))
(expect-true "underline is on the cell" (<> 0 ?*at-b*))
(expect-true "and is not the same bits as bold" (<> ?*at-a* ?*at-b*))
(expect "attroff A_UNDERLINE" OK (ncurses-attroff A_UNDERLINE))
(expect "and off again" 0 (attr-cell-attributes))

; ------------------------------------------------------------
; every name the wrapper accepts
; ------------------------------------------------------------

(expect "A_STANDOUT" OK (ncurses-attron A_STANDOUT))
(expect "A_REVERSE" OK (ncurses-attron A_REVERSE))
(expect "A_BLINK" OK (ncurses-attron A_BLINK))
(expect "A_DIM" OK (ncurses-attron A_DIM))
(expect "A_PROTECT" OK (ncurses-attron A_PROTECT))
(expect "A_INVIS" OK (ncurses-attron A_INVIS))
(expect "A_ALTCHARSET" OK (ncurses-attron A_ALTCHARSET))
(expect "all of them off at once"
        OK (ncurses-attroff A_STANDOUT A_REVERSE A_BLINK A_DIM A_PROTECT A_INVIS A_ALTCHARSET))
(expect "leaves a clean cell" 0 (attr-cell-attributes))

; ------------------------------------------------------------
; several at once are ORed
; ------------------------------------------------------------

(expect "attron A_BOLD A_UNDERLINE" OK (ncurses-attron A_BOLD A_UNDERLINE))
(expect "the cell has both" (+ ?*at-a* ?*at-b*) (attr-cell-attributes))
(expect "attroff of one of them" OK (ncurses-attroff A_BOLD))
(expect "leaves the other" ?*at-b* (attr-cell-attributes))
(expect "attroff of the other" OK (ncurses-attroff A_UNDERLINE))
(expect "leaves none" 0 (attr-cell-attributes))

; ------------------------------------------------------------
; an integer is taken as the bits themselves
; ------------------------------------------------------------

(expect "attron of the bold bits as an integer" OK (ncurses-attron ?*at-a*))
(expect "is bold" ?*at-a* (attr-cell-attributes))
(expect "attroff of the integer" OK (ncurses-attroff ?*at-a*))
(expect "is not" 0 (attr-cell-attributes))

(expect "a symbol and an integer mix" OK (ncurses-attron A_UNDERLINE ?*at-a*))
(expect "and both are on" (+ ?*at-a* ?*at-b*) (attr-cell-attributes))
(expect "attroff the same mix" OK (ncurses-attroff A_UNDERLINE ?*at-a*))
(expect "and both are off" 0 (attr-cell-attributes))

; ------------------------------------------------------------
; a name the wrapper does not know is refused whole
; ------------------------------------------------------------

(expect "attron refuses an unknown name" FALSE (ncurses-attron A_SPARKLY))
(expect "attroff refuses it too" FALSE (ncurses-attroff A_SPARKLY))
(expect "a known name before the unknown one does not rescue the call"
        FALSE (ncurses-attron A_BOLD A_SPARKLY))
(expect "and nothing was turned on by the refused call" 0 (attr-cell-attributes))
