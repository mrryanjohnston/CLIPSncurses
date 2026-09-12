(watch all)
; ============================================================
; ncurses dashboard demo — window-based, declarative
; ============================================================

; ------------------------------------------------------------
; templates
; ------------------------------------------------------------

(deftemplate app
  (slot focus)      ; menu | main | inspect
  (slot dirty))

(deftemplate win
  (slot name)
  (slot ptr))       ; WINDOW*

(deftemplate menu
  (slot index)
  (multislot items))

(deftemplate inspect
  (slot tab))       ; facts | rules | agenda | modules

(deftemplate key
  (slot ch))

(deftemplate status
  (slot msg))

; ------------------------------------------------------------
; startup state
; ------------------------------------------------------------

(deffacts startup
  (app (focus menu) (dirty TRUE))
  (menu (index 0)
        (items "Run" "Inspect: Facts" "Inspect: Rules" "Inspect: Agenda" "Help" "Quit"))
  (inspect (tab facts))
  (status (msg "↑↓ move  Tab focus  Enter select  i tab  q quit")))

; ------------------------------------------------------------
; window creation (once)
; ------------------------------------------------------------

(defrule create-windows
  (not (win (name menu)))
  =>
  (assert (win (name menu)
               (ptr (ncurses-newwin 20 24 0 0))))
  (assert (win (name main)
               (ptr (ncurses-newwin 20 40 0 24))))
  (assert (win (name inspect)
               (ptr (ncurses-newwin 20 16 0 64))))
  (assert (win (name status)
               (ptr (ncurses-newwin 4 80 20 0)))))

; ------------------------------------------------------------
; rendering helpers
; ------------------------------------------------------------

(deffunction draw-bordered-window (?w)
  (ncurses-wborder
    ?w
    ACS_VLINE ACS_VLINE
    ACS_HLINE ACS_HLINE
    ACS_ULCORNER ACS_URCORNER
    ACS_LLCORNER ACS_LRCORNER))

; ------------------------------------------------------------
; render menu pane
; ------------------------------------------------------------

(defrule render-menu
  (app (dirty TRUE) (focus ?focus))
  ?m <- (menu (index ?i) (items $?items))
  (win (name menu) (ptr ?w))
  =>
  (ncurses-wclear ?w)
  (draw-bordered-window ?w)
  (ncurses-mvwprintw ?w 1 2 "Menu")

  (loop-for-count (?n 0 (- (length$ ?items) 1))
    (ncurses-mvwprintw
      ?w
      (+ 3 ?n)
      2
      (nth$ (+ 1 ?n) ?items))
    (if (= ?n ?i) then
      (ncurses-mvwprintw
        ?w
        (+ 3 ?n)
        1
        ">")))

  (if (eq ?focus menu) then
    (ncurses-mvwprintw ?w 18 2 "[focus]"))

  (ncurses-wrefresh ?w)
  (assert (menu-rendered)))

; ------------------------------------------------------------
; render main pane
; ------------------------------------------------------------

(defrule render-main
  (app (dirty TRUE) (focus ?focus))
  (win (name main) (ptr ?w))
  =>
  (ncurses-wclear ?w)
  (draw-bordered-window ?w)

  (ncurses-mvwprintw ?w 1 2 "Main")
  (ncurses-mvwprintw ?w 3 2 "State-driven dashboard")
  (ncurses-mvwprintw ?w 5 2 (str-cat "Focus: " ?focus))

  (ncurses-wrefresh ?w)
  (assert (main-rendered)))

; ------------------------------------------------------------
; render inspect pane
; ------------------------------------------------------------

(defrule render-inspect
  (app (dirty TRUE))
  (inspect (tab ?tab))
  (win (name inspect) (ptr ?w))
  =>
  (ncurses-wclear ?w)
  (draw-bordered-window ?w)

  (ncurses-mvwprintw ?w 1 2 (str-cat "Inspect: " ?tab))

  (switch ?tab
    (case facts then
      (ncurses-mvwprintw ?w 3 2 (str-cat "facts: " (length$ (get-fact-list)))))
    (case rules then
      (ncurses-mvwprintw ?w 3 2 (str-cat "rules: " (length$ (get-defrule-list)))))
    (case agenda then
      (ncurses-mvwprintw ?w 3 2 (str-cat "focus stack: " (length$ (get-focus-stack)))))
    (case modules then
      (ncurses-mvwprintw ?w 3 2 (str-cat "modules: " (length$ (get-defmodule-list))))))

  (ncurses-wrefresh ?w)
  (assert (inspect-rendered)))

; ------------------------------------------------------------
; render status bar
; ------------------------------------------------------------

(defrule render-status
  (app (dirty TRUE))
  (status (msg ?msg))
  (win (name status) (ptr ?w))
  =>
  (ncurses-wclear ?w)
  (ncurses-box ?w ACS_HLINE ACS_HLINE)
  (ncurses-mvwprintw ?w 1 2 ?msg)
  (ncurses-wrefresh ?w)
  (assert (status-rendered)))

; ------------------------------------------------------------
; finalize render + input
; ------------------------------------------------------------

(defrule finish-render
  ?a <- (app (dirty TRUE))
  (menu-rendered)
  (main-rendered)
  (inspect-rendered)
  (status-rendered)
  =>
  (modify ?a (dirty FALSE)))

(defrule get-input
  (app (dirty FALSE))
  =>
  (assert (key (ch (ncurses-key-to-str (ncurses-getch))))))

; ------------------------------------------------------------
; focus cycling
; ------------------------------------------------------------

(defrule cycle-focus
  ?k <- (key (ch 9)) ; TAB
  ?a <- (app (focus ?f))
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  =>
  (retract ?k ?me ?ma ?i ?s)
  (modify ?a
    (focus (switch ?f
             (case menu then main)
             (case main then inspect)
             (case inspect then menu)))
    (dirty TRUE)))

; ------------------------------------------------------------
; menu navigation
; ------------------------------------------------------------

(defrule menu-down
  ?a <- (app (focus menu))
  ?m <- (menu (index ?index) (items $?items))
  ?k <- (key (ch KEY_DOWN))
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  =>
  (retract ?k ?me ?ma ?i ?s)
  (modify ?m (index (mod (+ ?index 1) (length$ ?items))))
  (modify ?a (dirty TRUE)))

(defrule menu-up
  ?a <- (app (focus menu))
  ?m <- (menu (index ?index) (items $?items))
  ?k <- (key (ch KEY_UP))
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  =>
  (retract ?k ?me ?ma ?i ?s)
  (modify ?m (index (mod (+ ?index (- (length$ ?items) 1))
                          (length$ ?items))))
  (modify ?a (dirty TRUE)))

; ------------------------------------------------------------
; menu selection
; ------------------------------------------------------------

(defrule menu-select-inspect-facts
  ?a <- (app (focus menu))
  ?k <- (key (ch 10))
  (menu (index ?index) (items $?items))
  ?ins <- (inspect)
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  (test (eq (nth$ (+ 1 ?index) ?items) "Inspect: Facts"))
  =>
  (retract ?k ?me ?ma ?i ?s)
  (modify ?ins (tab facts))
  (modify ?a (dirty TRUE)))

(defrule menu-select-inspect-rules
  ?a <- (app (focus menu))
  ?k <- (key (ch 10))
  (menu (index ?index) (items $?items))
  ?ins <- (inspect)
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  (test (eq (nth$ (+ 1 ?index) ?items) "Inspect: Rules"))
  =>
  (retract ?k ?me ?ma ?i ?s)
  (modify ?ins (tab rules))
  (modify ?a (dirty TRUE)))

(defrule menu-select-inspect-agenda
  ?a <- (app (focus menu))
  ?k <- (key (ch 10))
  (menu (index ?index) (items $?items))
  ?ins <- (inspect)
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  (test (eq (nth$ (+ 1 ?index) ?items) "Inspect: Agenda"))
  =>
  (retract ?k ?me ?ma ?i ?s)
  (modify ?ins (tab agenda))
  (modify ?a (dirty TRUE)))

(defrule menu-select-inspect-quit
  ?a <- (app (focus menu))
  ?k <- (key (ch 10))
  (menu (index ?index) (items $?items))
  ?ins <- (inspect)
  ?me <- (menu-rendered)
  ?ma <- (main-rendered)
  ?i <- (inspect-rendered)
  ?s <- (status-rendered)
  (test (eq (nth$ (+ 1 ?index) ?items) "Quit"))
  =>
  (retract ?k)
  (ncurses-endwin)
  (exit))

(defrule menu-select-quit
  ?k <- (key (ch q))
  =>
  (retract ?k)
  (ncurses-endwin)
  (exit))

; ------------------------------------------------------------
; ignore everything else
; ------------------------------------------------------------

(defrule ignore-key
  ?a <- (app (dirty FALSE))
  ?k <- (key (ch ~9&~10&~KEY_DOWN&~KEY_UP))
  =>
  (retract ?k)
  (modify ?a (dirty TRUE)))

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
(ncurses-refresh)
(run)
