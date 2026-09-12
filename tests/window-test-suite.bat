; ============================================================
; WINDOWS
;
; newwin, and everything that takes a window pointer: getmaxyx, getyx,
; mvwprintw, box and wborder, wclear, wrefresh, wtimeout, delwin.  What is
; drawn into a window cannot be read back from CLIPS -- inch reads stdscr
; only -- so the window's cursor, which mvwprintw moves, is the witness
; that text went in.
; ============================================================

(fresh-screen)

(defglobal
  ?*wn-win* = FALSE
  ?*wn-r*   = nothing)

; ------------------------------------------------------------
; newwin: lines, columns, then where the top-left corner goes
; ------------------------------------------------------------

(bind ?*wn-win* (ncurses-newwin 5 12 3 4))
(expect "newwin answers a pointer" EXTERNAL-ADDRESS (type ?*wn-win*))
(expect "getmaxyx of it is the size asked for" (create$ 5 12) (ncurses-getmaxyx ?*wn-win*))
(expect "its cursor starts at its own origin" (create$ 0 0) (ncurses-getyx ?*wn-win*))
(expect "stdscr is still full size" (create$ 24 80) (ncurses-getmaxyx stdscr))

; ------------------------------------------------------------
; mvwprintw: window, row, column, text -- row first, unlike mvprintw
; ------------------------------------------------------------

(expect "mvwprintw at row 1, column 2" OK (ncurses-mvwprintw ?*wn-win* 1 2 "hey"))
(expect "the window's cursor ends after the text" (create$ 1 5) (ncurses-getyx ?*wn-win*))
(expect "stdscr's cursor did not move" (create$ 0 0) (ncurses-getyx stdscr))

(expect "mvwprintw of the empty string" OK (ncurses-mvwprintw ?*wn-win* 4 11 ""))
(expect "moves to the last cell" (create$ 4 11) (ncurses-getyx ?*wn-win*))

(expect "mvwprintw past the window's edge is ERR" ERR (ncurses-mvwprintw ?*wn-win* 5 0 "x"))
(expect "text that overruns a middle row wraps, and is OK" OK (ncurses-mvwprintw ?*wn-win* 0 8 "toolong"))
(expect "onto the next row" (create$ 1 3) (ncurses-getyx ?*wn-win*))
(expect "text that overruns the last row has nowhere to go, and is ERR" ERR (ncurses-mvwprintw ?*wn-win* 4 8 "toolong"))

(expect "mvwprintw on stdscr by name" OK (ncurses-mvwprintw stdscr 7 9 "abc"))
(expect "moves stdscr's cursor" (create$ 7 12) (ncurses-getyx stdscr))
(ncurses-move 7 9)
(expect "and wrote there" 97 (ncurses-inch))

; ------------------------------------------------------------
; drawing edges into a window: only the status can be seen
; ------------------------------------------------------------

(expect "box on a window" OK (ncurses-box ?*wn-win* 0 0))
(expect "wborder on a window" OK (ncurses-wborder ?*wn-win* v v h h A B C D))
(expect "neither reached stdscr" 32 (bd-char-at 3 4))

; ------------------------------------------------------------
; refreshing and clearing
; ------------------------------------------------------------

(expect "wrefresh" OK (ncurses-wrefresh ?*wn-win*))
(expect "wrefresh of stdscr by name" OK (ncurses-wrefresh stdscr))
(expect "wclear" OK (ncurses-wclear ?*wn-win*))
(expect "wclear homes the window's cursor" (create$ 0 0) (ncurses-getyx ?*wn-win*))
(expect "wclear of stdscr by name" OK (ncurses-wclear stdscr))
(ncurses-move 7 9)
(expect "wiped what mvwprintw put on stdscr" 32 (ncurses-inch))

; ------------------------------------------------------------
; timeouts answer TRUE: ncurses has nothing to say about them
; ------------------------------------------------------------

(expect "wtimeout" TRUE (ncurses-wtimeout ?*wn-win* 100))
(expect "wtimeout of -1, blocking" TRUE (ncurses-wtimeout ?*wn-win* -1))
(expect "timeout on stdscr" TRUE (ncurses-timeout 0))
(expect "timeout of -1" TRUE (ncurses-timeout -1))

; ------------------------------------------------------------
; more than one window
; ------------------------------------------------------------

(defglobal ?*wn-other* = (ncurses-newwin 2 3 20 70))
(expect "a second window" EXTERNAL-ADDRESS (type ?*wn-other*))
(expect "with its own size" (create$ 2 3) (ncurses-getmaxyx ?*wn-other*))
(expect "the first keeps its size" (create$ 5 12) (ncurses-getmaxyx ?*wn-win*))
(expect-true "they are different pointers" (neq ?*wn-win* ?*wn-other*))

; ncurses takes 0 for "to the edge of the screen"
(defglobal ?*wn-full* = (ncurses-newwin 0 0 0 0))
(expect "newwin 0 0 0 0 is the whole screen" (create$ 24 80) (ncurses-getmaxyx ?*wn-full*))

; ------------------------------------------------------------
; delwin
; ------------------------------------------------------------

(expect "delwin" OK (ncurses-delwin ?*wn-win*))
(expect "delwin of the second" OK (ncurses-delwin ?*wn-other*))
(expect "delwin of the full-screen one" OK (ncurses-delwin ?*wn-full*))

; ------------------------------------------------------------
; a window that cannot be made
; ------------------------------------------------------------

(bind ?*wn-r* (ncurses-newwin -1 -1 0 0))
(expect "newwin with a negative size is refused" FALSE ?*wn-r*)
