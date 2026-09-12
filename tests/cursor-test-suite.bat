; ============================================================
; THE CURSOR AND SINGLE CHARACTERS
;
; move, getyx, addch, inch and mvprintw on stdscr.  Every position is read
; back with getyx, and every character written is read back with inch, so
; these are round trips through the screen rather than checks of a status.
;
; Argument order is part of what is asserted.  ncurses-move takes (y x), as
; ncurses does.  ncurses-mvprintw takes (x y string): the column first.
; That is what the examples rely on, and it is the wrapper as it stands.
; ============================================================

(fresh-screen)

; ------------------------------------------------------------
; move and getyx
; ------------------------------------------------------------

(expect "move to the origin" OK (ncurses-move 0 0))
(expect "getyx reads it back" (create$ 0 0) (ncurses-getyx stdscr))

(expect "move to row 5, column 7" OK (ncurses-move 5 7))
(expect "getyx answers (y x), so row first" (create$ 5 7) (ncurses-getyx stdscr))

(expect "move to the last cell" OK (ncurses-move 23 79))
(expect "getyx" (create$ 23 79) (ncurses-getyx stdscr))

(expect "move one row past the bottom is ERR" ERR (ncurses-move 24 0))
(expect "move one column past the right edge is ERR" ERR (ncurses-move 0 80))
(expect "move to a negative row is ERR" ERR (ncurses-move -1 0))
(expect "a refused move leaves the cursor where it was" (create$ 23 79) (ncurses-getyx stdscr))

; ------------------------------------------------------------
; addch and inch
;
; addch takes the character as an integer and advances the cursor; inch
; reads the character under the cursor.
; ------------------------------------------------------------

(ncurses-move 2 3)
(expect "addch A" OK (ncurses-addch 65))
(expect "addch moved the cursor one column right" (create$ 2 4) (ncurses-getyx stdscr))

(ncurses-move 2 3)
(expect "inch reads the A back" 65 (ncurses-inch))
(expect "and did not move the cursor" (create$ 2 3) (ncurses-getyx stdscr))

(ncurses-move 2 4)
(expect "the cell after it is still blank" 32 (ncurses-inch))

; a second addch overwrites
(ncurses-move 2 3)
(ncurses-addch 66)
(ncurses-move 2 3)
(expect "addch overwrites" 66 (ncurses-inch))

; addch at the right edge wraps to the next line, as ncurses does
(ncurses-move 4 79)
(expect "addch in the last column" OK (ncurses-addch 67))
(expect "wraps the cursor to the start of the next row" (create$ 5 0) (ncurses-getyx stdscr))

; ------------------------------------------------------------
; mvprintw: column, row, string
; ------------------------------------------------------------

(expect "mvprintw at column 10, row 6" OK (ncurses-mvprintw 10 6 "hello"))
(expect "the cursor ends after the text, on row 6" (create$ 6 15) (ncurses-getyx stdscr))

(ncurses-move 6 10)
(expect "the first character is where the column said" 104 (ncurses-inch))
(ncurses-move 6 14)
(expect "and the last" 111 (ncurses-inch))
(ncurses-move 6 9)
(expect "the cell before the text is blank" 32 (ncurses-inch))

(expect "mvprintw of the empty string" OK (ncurses-mvprintw 0 0 ""))
(expect "only moves the cursor" (create$ 0 0) (ncurses-getyx stdscr))

(expect "mvprintw off the screen is ERR" ERR (ncurses-mvprintw 200 200 "x"))

; text that runs past the right edge wraps onto the next row, as addch
; does
(expect "mvprintw that runs off the right edge" OK (ncurses-mvprintw 75 8 "abcdefgh"))
(expect "leaves the cursor after the last character, on the next row" (create$ 9 3) (ncurses-getyx stdscr))
(ncurses-move 8 79)
(expect "the text filled the row" 101 (ncurses-inch))
(ncurses-move 9 0)
(expect "and continued on the next" 102 (ncurses-inch))

; on the last row there is nowhere to wrap to, and that is ERR -- but
; what fit is still written
(expect "mvprintw that runs off the bottom-right corner is ERR" ERR (ncurses-mvprintw 75 23 "abcdefgh"))
(ncurses-move 23 75)
(expect "the part that fit is on the screen" 97 (ncurses-inch))
(ncurses-move 23 79)
(expect "up to the last column" 101 (ncurses-inch))

; ------------------------------------------------------------
; clear wipes everything above
; ------------------------------------------------------------

(expect "clear" OK (ncurses-clear))
(ncurses-move 6 10)
(expect "the text is gone" 32 (ncurses-inch))
(ncurses-move 2 3)
(expect "so is the character" 32 (ncurses-inch))
