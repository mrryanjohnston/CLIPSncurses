;(watch all)
; ============================================================
; ncurses TUI demo (multi-screen, status bar, options)
; ============================================================

(deftemplate screen
  (slot name))

(deftemplate menu
  (slot index)
  (multislot items))

(deftemplate option
  (slot name)
  (slot value))

(deftemplate key
  (slot ch))

(deffacts startup
  (screen (name main))
  (menu
    (index 0)
    (items "Start" "Options" "Help" "Quit"))
  (option (name sound) (value on))
  (option (name difficulty) (value normal)))

; ------------------------------------------------------------
; draw main menu
; ------------------------------------------------------------

(defrule draw-main-menu
  (screen (name main))
  ?m <- (menu (index ?i) (items $?items))
  =>
  (ncurses-clear)
  (ncurses-mvprintw 2 0 "CLIPS ncurses demo")
  (ncurses-mvprintw 2 1 "Use ↑ ↓ Enter")

  (loop-for-count (?n 0 (- (length$ ?items) 1))
    (ncurses-mvprintw
      4
      (+ 3 ?n)
      (nth$ (+ 1 ?n) ?items))
    (if (= ?n ?i) then
      (ncurses-mvprintw
        2
        (+ 3 ?n)
        ">")))

  (ncurses-refresh)
  (assert (key (ch (ncurses-getch)))))

; ------------------------------------------------------------
; navigation
; ------------------------------------------------------------

(defrule main-down
  (screen (name main))
  ?m <- (menu (index ?i) (items $?items))
  ?k <- (key (ch KEY_DOWN))
  =>
  (retract ?k)
  (modify ?m (index (mod (+ ?i 1) (length$ ?items)))))

(defrule main-up
  (screen (name main))
  ?m <- (menu (index ?i) (items $?items))
  ?k <- (key (ch KEY_UP))
  =>
  (retract ?k)
  (modify ?m (index (mod (+ ?i (- (length$ ?items) 1))
                          (length$ ?items)))))

; ------------------------------------------------------------
; select main items
; ------------------------------------------------------------

(defrule select-start
  ?k <- (key (ch 10))
  ?s <- (screen (name main))
  (menu (index ?i) (items $?items))
  (test (eq (nth$ (+ 1 ?i) ?items) "Start"))
  =>
  (retract ?k ?s)
  (assert (screen (name start))))

(defrule select-options
  ?k <- (key (ch 10))
  ?s <- (screen (name main))
  (menu (index ?i) (items $?items))
  (test (eq (nth$ (+ 1 ?i) ?items) "Options"))
  =>
  (retract ?k ?s)
  (assert (screen (name options))))

(defrule select-help
  ?k <- (key (ch 10))
  ?s <- (screen (name main))
  (menu (index ?i) (items $?items))
  (test (eq (nth$ (+ 1 ?i) ?items) "Help"))
  =>
  (retract ?k ?s)
  (assert (screen (name help))))

(defrule select-quit
  (key (ch 10))
  (screen (name main))
  (menu (index ?i) (items $?items))
  (test (eq (nth$ (+ 1 ?i) ?items) "Quit"))
  =>
  (ncurses-endwin)
  (exit))

; ------------------------------------------------------------
; start screen
; ------------------------------------------------------------

(defrule draw-start
  (screen (name start))
  =>
  (ncurses-clear)
  (ncurses-mvprintw 4 2 "Starting the game...")
  (ncurses-mvprintw 4 4 "Press any key to return")
  (ncurses-refresh)
  (assert (key (ch (ncurses-getch)))))

(defrule leave-start
  ?k <- (key)
  ?s <- (screen (name start))
  =>
  (retract ?k ?s)
  (assert (screen (name main))))

; ------------------------------------------------------------
; options screen
; ------------------------------------------------------------

(defrule draw-options
  (screen (name options))
  (option (name sound) (value ?s))
  (option (name difficulty) (value ?d))
  =>
  (ncurses-clear)
  (ncurses-mvprintw 2 1 "Options")
  (ncurses-mvprintw 4 3 (str-cat "Sound: " ?s))
  (ncurses-mvprintw 4 4 (str-cat "Difficulty: " ?d))
  (ncurses-mvprintw 4 6 "Press any key to return")
  (ncurses-refresh)
  (assert (key (ch (ncurses-getch)))))

(defrule leave-options
  ?k <- (key)
  ?s <- (screen (name options))
  =>
  (retract ?k ?s)
  (assert (screen (name main))))

; ------------------------------------------------------------
; help screen
; ------------------------------------------------------------

(defrule draw-help
  (screen (name help))
  =>
  (ncurses-clear)
  (ncurses-mvprintw 2 1 "Help")
  (ncurses-mvprintw 4 3 "Arrow keys move the cursor.")
  (ncurses-mvprintw 4 4 "Enter selects.")
  (ncurses-mvprintw 4 6 "Press any key to return.")
  (ncurses-refresh)
  (assert (key (ch (ncurses-getch)))))

(defrule leave-help
  ?k <- (key)
  ?s <- (screen (name help))
  =>
  (retract ?k ?s)
  (assert (screen (name main))))

; ------------------------------------------------------------
; ignore everything else
; ------------------------------------------------------------

(defrule ignore-key
  ?k <- (key)
  =>
  (retract ?k)
  (assert (key (ch (ncurses-getch)))))

; ------------------------------------------------------------
; bootstrap
; ------------------------------------------------------------

(reset)
(ncurses-initscr)
(ncurses-noecho)
(ncurses-cbreak)
(ncurses-keypad stdscr TRUE)
(ncurses-leaveok stdscr FALSE)
(ncurses-curs-set 0)
(run)
(exit)
