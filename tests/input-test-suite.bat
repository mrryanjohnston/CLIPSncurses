; ============================================================
; INPUT
;
; getch reads from standard input, which under tests/run.sh is these bytes
; and nothing more:
;
;     a  ESC O A  ESC O B  ESC O C  LF
;
; ESC O A, ESC O B and ESC O C are what an xterm sends for the up, down and
; right arrow keys with the keypad in transmit mode, and TERM is pinned to
; xterm so that ncurses knows them as such.  With keypad on, getch answers
; one key code for the three bytes; with it off, the three bytes.
;
; Past the end of the input getch answers -1 (ERR) at once, whatever the
; timeout, so nothing here can block.
; ============================================================

(fresh-screen)

; ------------------------------------------------------------
; getch, with the keypad on and off
; ------------------------------------------------------------

(ncurses-keypad stdscr TRUE)
(ncurses-timeout -1)

(expect "the first byte is a" 97 (ncurses-getch))
(expect "with the keypad on, ESC O A is KEY_UP" 259 (ncurses-getch))

(ncurses-keypad stdscr FALSE)
(expect "with the keypad off, the escape comes through as itself" 27 (ncurses-getch))
(expect "then O" 79 (ncurses-getch))
(expect "then B" 66 (ncurses-getch))

(ncurses-keypad stdscr TRUE)
(expect "with it on again, ESC O C is KEY_RIGHT" 261 (ncurses-getch))
(expect "a newline is 10" 10 (ncurses-getch))

(expect "at the end of the input, getch is -1" -1 (ncurses-getch))
(ncurses-timeout 0)
(expect "and with a zero timeout" -1 (ncurses-getch))
(ncurses-timeout -1)
(expect "and still, on a later call" -1 (ncurses-getch))

; ------------------------------------------------------------
; key-to-str
;
; A printable character becomes a symbol of that character, a key ncurses
; names becomes that name, and anything else comes back as the integer it
; was.  The codes are ncurses' own: KEY_DOWN is 258, KEY_F0 is 264 and the
; function keys count up from there.
; ------------------------------------------------------------

(expect "A" A (ncurses-key-to-str 65))
(expect "a" a (ncurses-key-to-str 97))
(expect "a digit" (sym-cat 7) (ncurses-key-to-str 55))
(expect "a space" (sym-cat " ") (ncurses-key-to-str 32))
(expect "and it is a symbol" SYMBOL (type (ncurses-key-to-str 32)))
(expect "tilde, the last printable" (sym-cat "~") (ncurses-key-to-str 126))

(expect "DEL is not printable, and stays an integer" 127 (ncurses-key-to-str 127))
(expect "so does a newline" 10 (ncurses-key-to-str 10))
(expect "and a tab" 9 (ncurses-key-to-str 9))
(expect "and NUL" 0 (ncurses-key-to-str 0))
(expect "and -1, what getch answers with nothing to read" -1 (ncurses-key-to-str -1))
(expect "the integer that comes back is an integer" INTEGER (type (ncurses-key-to-str 10)))

(expect "KEY_MIN" KEY_MIN (ncurses-key-to-str 257))
(expect "KEY_DOWN" KEY_DOWN (ncurses-key-to-str 258))
(expect "KEY_UP" KEY_UP (ncurses-key-to-str 259))
(expect "KEY_LEFT" KEY_LEFT (ncurses-key-to-str 260))
(expect "KEY_RIGHT" KEY_RIGHT (ncurses-key-to-str 261))
(expect "KEY_HOME" KEY_HOME (ncurses-key-to-str 262))
(expect "KEY_BACKSPACE" KEY_BACKSPACE (ncurses-key-to-str 263))

(expect "KEY_F0" (sym-cat "KEY_F(0)") (ncurses-key-to-str 264))
(expect "KEY_F1" (sym-cat "KEY_F(1)") (ncurses-key-to-str 265))
(expect "KEY_F12" (sym-cat "KEY_F(12)") (ncurses-key-to-str 276))

; what getch answered above goes through the same table
(expect "the name of what the keypad read" KEY_UP (ncurses-key-to-str 259))
