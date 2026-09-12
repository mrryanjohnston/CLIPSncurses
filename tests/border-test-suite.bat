; ============================================================
; BORDERS AND BOXES
;
; border, wborder and box draw the edges of a window, and inch at the
; corners and edges of stdscr is how the drawing is checked.  The sides go
; in ncurses' order: left, right, top, bottom, top-left, top-right,
; bottom-left, bottom-right.
;
; Each side is a chtype, and this is where the wrapper's symbolic spelling
; of one is reachable: a one-character symbol is that character, an ACS_*
; name is the line-drawing character of that name in the terminal's
; alternate character set.  border and wborder take symbols only; box takes
; a symbol or an integer.
;
; tests/run.sh pins TERM to xterm, whose alternate character set spells
; ACS_ULCORNER as l, ACS_HLINE as q and so on, so those are asserted.
; ============================================================

(fresh-screen)

; the character in the cell at (y x)
(deffunction bd-char-at (?y ?x)
  (ncurses-move ?y ?x)
  (ncurses-chtype-character (ncurses-inch)))

; ------------------------------------------------------------
; border on stdscr, with plain characters
; ------------------------------------------------------------

(expect "border with one-character symbols" OK (ncurses-border L R T B a b c d))

(expect "top-left corner" 97 (bd-char-at 0 0))
(expect "top-right corner" 98 (bd-char-at 0 79))
(expect "bottom-left corner" 99 (bd-char-at 23 0))
(expect "bottom-right corner" 100 (bd-char-at 23 79))
(expect "left side" 76 (bd-char-at 11 0))
(expect "right side" 82 (bd-char-at 11 79))
(expect "top side" 84 (bd-char-at 0 40))
(expect "bottom side" 66 (bd-char-at 23 40))
(expect "the inside is untouched" 32 (bd-char-at 11 40))

; ------------------------------------------------------------
; border with ACS names
; ------------------------------------------------------------

(expect "border with ACS names"
        OK (ncurses-border ACS_VLINE ACS_VLINE ACS_HLINE ACS_HLINE
                           ACS_ULCORNER ACS_URCORNER ACS_LLCORNER ACS_LRCORNER))

(expect "ACS_ULCORNER is l in xterm's alternate set" 108 (bd-char-at 0 0))
(expect "ACS_URCORNER is k" 107 (bd-char-at 0 79))
(expect "ACS_LLCORNER is m" 109 (bd-char-at 23 0))
(expect "ACS_LRCORNER is j" 106 (bd-char-at 23 79))
(expect "ACS_VLINE is x" 120 (bd-char-at 11 0))
(expect "ACS_HLINE is q" 113 (bd-char-at 0 40))

(ncurses-move 0 0)
(expect-true "an ACS cell carries the alternate-character-set attribute"
             (<> 0 (ncurses-chtype-attributes (ncurses-inch))))
(ncurses-move 11 40)
(expect "a plain cell does not" 0 (ncurses-chtype-attributes (ncurses-inch)))

; a name that is not one of ncurses' is refused, and refused before
; anything is drawn
(ncurses-clear)
(expect "border refuses a name that is not an ACS name"
        FALSE (ncurses-border ACS_NOTHING L L L L L L L))
(expect "and drew nothing" 32 (bd-char-at 11 0))
(expect "in any position"
        FALSE (ncurses-border L L L L L L L ACS_NOTHING))
(expect "a symbol longer than one character that is not an ACS name is refused"
        FALSE (ncurses-border LL L L L L L L L))

; ------------------------------------------------------------
; wborder: the same with the window named first
; ------------------------------------------------------------

(ncurses-clear)
(expect "wborder on stdscr by name" OK (ncurses-wborder stdscr v v h h A B C D))
(expect "top-left" 65 (bd-char-at 0 0))
(expect "top-right" 66 (bd-char-at 0 79))
(expect "bottom-left" 67 (bd-char-at 23 0))
(expect "bottom-right" 68 (bd-char-at 23 79))
(expect "left" 118 (bd-char-at 11 0))
(expect "top" 104 (bd-char-at 0 40))

(ncurses-clear)
(expect "wborder on stdscr by pointer" OK (ncurses-wborder ?*sc-stdscr* v v h h A B C D))
(expect "drew the same border" 65 (bd-char-at 0 0))

(expect "wborder refuses a bad ACS name" FALSE (ncurses-wborder stdscr ACS_NOTHING v h h A B C D))

; ------------------------------------------------------------
; box: vertical then horizontal, corners chosen by ncurses
; ------------------------------------------------------------

(ncurses-clear)
(expect "box with symbols" OK (ncurses-box stdscr V H))
(expect "left side" 86 (bd-char-at 11 0))
(expect "right side" 86 (bd-char-at 11 79))
(expect "top side" 72 (bd-char-at 0 40))
(expect "bottom side" 72 (bd-char-at 23 40))
(expect "the corner is ACS_ULCORNER, l" 108 (bd-char-at 0 0))

(ncurses-clear)
(expect "box with integers" OK (ncurses-box stdscr 120 121))
(expect "left side" 120 (bd-char-at 11 0))
(expect "top side" 121 (bd-char-at 0 40))

(ncurses-clear)
(expect "box with ACS names" OK (ncurses-box stdscr ACS_VLINE ACS_HLINE))
(expect "left side is x" 120 (bd-char-at 11 0))
(expect "top side is q" 113 (bd-char-at 0 40))

; the ncurses convention: 0 means the default line-drawing character
(ncurses-clear)
(expect "box with 0 0 takes the defaults" OK (ncurses-box stdscr 0 0))
(expect "which are ACS_VLINE" 120 (bd-char-at 11 0))
(expect "and ACS_HLINE" 113 (bd-char-at 0 40))

(expect "box refuses a bad ACS name" FALSE (ncurses-box stdscr ACS_NOTHING H))
(expect "in either position" FALSE (ncurses-box stdscr V ACS_NOTHING))
