; ============================================================
; THE SCREEN
;
; initscr and everything that configures stdscr as a whole: its size, the
; input modes, the per-window options, cursor visibility, colour.  This
; suite runs first because everything after it draws on the screen it
; opens.
;
; tests/run.sh pins the terminal to xterm at 24 lines by 80 columns, so the
; size is asserted exactly rather than as "something positive".
; ============================================================

(defglobal ?*sc-stdscr* = (ncurses-initscr))

(expect "initscr answers a pointer" EXTERNAL-ADDRESS (type ?*sc-stdscr*))

; ------------------------------------------------------------
; size: three spellings of one fact
; ------------------------------------------------------------

(expect "lines is 24" 24 (ncurses-lines))
(expect "cols is 80" 80 (ncurses-cols))
(expect "getmaxyx of stdscr is (lines cols)" (create$ 24 80) (ncurses-getmaxyx stdscr))
(expect "getmaxyx takes the pointer initscr returned as well as the symbol"
        (ncurses-getmaxyx stdscr) (ncurses-getmaxyx ?*sc-stdscr*))

; ------------------------------------------------------------
; input modes
;
; echo and noecho are kept inside ncurses and answer OK anywhere.  cbreak
; has to change the tty's line discipline, and there is no tty under
; tests/run.sh, so what it answers is ncurses reporting that.
; ------------------------------------------------------------

(expect "noecho" OK (ncurses-noecho))
(expect "echo" OK (ncurses-echo))
(expect "and noecho again, so nothing below is echoed" OK (ncurses-noecho))
(expect-status "cbreak is passed through and reports what ncurses said" (ncurses-cbreak))

; ------------------------------------------------------------
; refreshing
; ------------------------------------------------------------

(expect "clear" OK (ncurses-clear))
(expect "refresh" OK (ncurses-refresh))
(expect "doupdate" OK (ncurses-doupdate))

; ------------------------------------------------------------
; keypad and leaveok: window then flag, both optional
;
; Both arguments default: no window means stdscr, no flag means TRUE.
; ------------------------------------------------------------

(expect "keypad with no arguments" OK (ncurses-keypad))
(expect "keypad stdscr" OK (ncurses-keypad stdscr))
(expect "keypad stdscr TRUE" OK (ncurses-keypad stdscr TRUE))
(expect "keypad stdscr FALSE" OK (ncurses-keypad stdscr FALSE))
(expect "keypad takes the pointer" OK (ncurses-keypad ?*sc-stdscr* TRUE))

(expect "leaveok with no arguments" OK (ncurses-leaveok))
(expect "leaveok stdscr FALSE" OK (ncurses-leaveok stdscr FALSE))
(expect "leaveok takes the pointer" OK (ncurses-leaveok ?*sc-stdscr* FALSE))

; ------------------------------------------------------------
; cursor visibility
;
; curs_set answers the previous setting, so each call here is checked
; against the one before it.  xterm supports all three.
; ------------------------------------------------------------

(expect "curs-set 1 (normal) answers the previous state, which was normal" 1 (ncurses-curs-set 1))
(expect "curs-set 0 (invisible) answers the normal it replaced" 1 (ncurses-curs-set 0))
(expect "curs-set 2 (very visible) answers the invisible it replaced" 0 (ncurses-curs-set 2))
(expect "curs-set 1 answers the very visible it replaced" 2 (ncurses-curs-set 1))

; ------------------------------------------------------------
; colour
; ------------------------------------------------------------

(expect "start-color" OK (ncurses-start-color))
