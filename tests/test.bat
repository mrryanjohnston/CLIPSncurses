; ======================================================================
; CLIPSncurses in-process test suite
;
; Every suite batched from here shares one CLIPS environment, one ncurses
; screen, one process and one assertion counter, and the run ends with a
; non-zero exit status if any assertion failed.
;
; Run it through tests/run.sh rather than by hand.  ncurses owns standard
; output (it is the screen) and standard input (it is the keyboard), and
; that script is what redirects the one, feeds the other, and pins the
; terminal to xterm at 24x80 so that the cell positions, key codes and
; line-drawing characters asserted below are the same on every machine.
; Run from a terminal instead, the report lands on top of the screen and
; the input suite waits for someone to type.
;
; The report goes to stderr for that reason: it is the only stream ncurses
; leaves alone.  It is also where the wrappers report a refused call, so a
; "ncurses-...: ... must be ..." line between two dots is a test exercising
; that refusal, not a test going wrong.
; ======================================================================

(defglobal
  ?*tests-ran*    = 0
  ?*tests-failed* = 0)

(deffunction expect (?msg ?expected ?actual)
  (bind ?*tests-ran* (+ ?*tests-ran* 1))
  (if (eq ?expected ?actual)
   then
     (printout stderr ".")
   else
     (bind ?*tests-failed* (+ ?*tests-failed* 1))
     (printout stderr crlf "FAILURE: " ?msg
             crlf "  expected=" ?expected
             crlf "  actual=" ?actual crlf)))

; For values that are real but not fixed -- a pointer, an attribute bit
; pattern.  Asserting the exact value would make the suite a record of this
; build of ncurses rather than of the wrapper.
(deffunction expect-true (?msg ?actual)
  (expect ?msg TRUE (if ?actual then TRUE else FALSE)))

; For the calls that answer OK or ERR.  Some of them -- cbreak, endwin --
; answer ERR when standard output is not a tty, which under tests/run.sh
; it never is.  What is asserted for those is that the wrapper passed the
; call through and reported what ncurses said, rather than refusing it.
(deffunction expect-status (?msg ?actual)
  (expect ?msg TRUE (if (or (eq ?actual OK) (eq ?actual ERR)) then TRUE else FALSE)))

; Every suite below asserts where a character landed on the screen, so
; each begins by wiping the last one's drawing.
(deffunction fresh-screen ()
  (ncurses-attroff A_STANDOUT A_UNDERLINE A_REVERSE A_BLINK A_DIM A_BOLD A_PROTECT A_INVIS A_ALTCHARSET)
  (ncurses-clear))

(printout stderr "CLIPSncurses test suite" crlf crlf)

(batch* tests/screen-test-suite.bat)
(batch* tests/cursor-test-suite.bat)
(batch* tests/chtype-test-suite.bat)
(batch* tests/attribute-test-suite.bat)
(batch* tests/border-test-suite.bat)
(batch* tests/window-test-suite.bat)
(batch* tests/input-test-suite.bat)
(batch* tests/arg-guard-test-suite.bat)

; ----------------------------------------------------------------------
; shutdown
; ----------------------------------------------------------------------

(printout stderr crlf)
(expect-status "endwin hands the terminal back" (ncurses-endwin))

(printout stderr crlf "Tests run: " ?*tests-ran* "  Failures: " ?*tests-failed* crlf)
(exit (if (> ?*tests-failed* 0) then 1 else 0))
