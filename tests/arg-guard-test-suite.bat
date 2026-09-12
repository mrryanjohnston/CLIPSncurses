; ============================================================
; ARGUMENT GUARDS
;
; Every wrapper is registered with an AddUDF restriction string, and CLIPS
; checks a literal argument against it when it parses the call: a string
; where an integer is wanted never reaches the wrapper at all.  That check
; is not the one tested here.  What is tested is the wrapper's own guard,
; the one that runs on an argument the restriction string lets through --
; a symbol that is not stdscr where a window is wanted, a symbol that is
; not TRUE or FALSE where a flag is, a name ncurses does not have.
;
; Every refusal here answers FALSE and says why on stderr.  Those lines
; are the exercise, not noise: a refusal without its line would be one the
; wrapper made silently.
; ============================================================

(fresh-screen)

(defglobal ?*ag-win* = (ncurses-newwin 2 2 0 0))

; ------------------------------------------------------------
; where a window is expected, only a pointer or the symbol stdscr will do
; ------------------------------------------------------------

(expect "getyx refuses a symbol that is not stdscr" FALSE (ncurses-getyx nope))
(expect "getmaxyx" FALSE (ncurses-getmaxyx nope))
(expect "mvwprintw" FALSE (ncurses-mvwprintw nope 0 0 "x"))
(expect "wclear" FALSE (ncurses-wclear nope))
(expect "wrefresh" FALSE (ncurses-wrefresh nope))
(expect "wtimeout" FALSE (ncurses-wtimeout nope 0))
(expect "wborder" FALSE (ncurses-wborder nope v v h h A B C D))
(expect "box" FALSE (ncurses-box nope V H))
(expect "delwin" FALSE (ncurses-delwin nope))
(expect "keypad" FALSE (ncurses-keypad nope))
(expect "leaveok" FALSE (ncurses-leaveok nope))

(expect "and the symbol has to be spelled exactly" FALSE (ncurses-getyx STDSCR))

; ------------------------------------------------------------
; where a flag is expected, only TRUE or FALSE will do
; ------------------------------------------------------------

(expect "keypad refuses a flag that is not TRUE or FALSE" FALSE (ncurses-keypad stdscr yes))
(expect "leaveok too" FALSE (ncurses-leaveok stdscr no))
(expect "a good window does not rescue a bad flag" FALSE (ncurses-keypad ?*ag-win* maybe))

; ------------------------------------------------------------
; where a chtype is expected, a symbol has to be one character or an
; ACS name
; ------------------------------------------------------------

(expect "border refuses an unknown name" FALSE (ncurses-border ACS_NOTHING v v v v v v v))
(expect "border refuses a two-character symbol" FALSE (ncurses-border vv v v v v v v v))
(expect "wborder" FALSE (ncurses-wborder ?*ag-win* v ACS_NOTHING v v v v v v))
(expect "box" FALSE (ncurses-box ?*ag-win* ACS_NOTHING H))

; ------------------------------------------------------------
; where an attribute is expected, only an A_* name or an integer will do
; ------------------------------------------------------------

(expect "attron refuses a name that is not an attribute" FALSE (ncurses-attron A_NOTHING))
(expect "attroff too" FALSE (ncurses-attroff A_NOTHING))
(expect "even after a good one" FALSE (ncurses-attron A_BOLD A_NOTHING))

; ------------------------------------------------------------
; values ncurses itself refuses come back as FALSE, not ERR
; ------------------------------------------------------------

(expect "curs-set refuses a visibility ncurses has no name for" FALSE (ncurses-curs-set 7))
(expect "and a negative one" FALSE (ncurses-curs-set -1))
(expect "newwin refuses a negative size" FALSE (ncurses-newwin -1 5 0 0))

; ------------------------------------------------------------
; a refused call changed nothing
; ------------------------------------------------------------

(expect "the window is still there and still its size" (create$ 2 2) (ncurses-getmaxyx ?*ag-win*))
(expect "delwin" OK (ncurses-delwin ?*ag-win*))
