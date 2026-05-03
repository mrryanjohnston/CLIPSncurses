; ============================================================
; ncurses TUI menu demo (minimal)
; ============================================================

(deftemplate menu
	(slot index)
	(multislot items))

(deftemplate key
	(slot ch))

(deffacts startup
	(menu
		(index 0)
		(items "Start" "Options" "Quit")))

(defrule draw-menu
	?m <- (menu (index ?i) (items $?items))
	=>
	(ncurses-clear)
	(ncurses-mvprintw 0 0 "CLIPS ncurses demo")

	(loop-for-count (?n 0 (- (length$ ?items) 1))
		(ncurses-mvprintw
			2
			(+ 2 ?n)
			(nth$ (+ 1 ?n) ?items))
		(if (= ?n ?i) then
			(ncurses-mvprintw
				12
				(+ 2 ?n)
				"<")))

	(ncurses-refresh)
	(assert (key (ch (ncurses-key-to-str (ncurses-getch))))))

(defrule move-down
	?m <- (menu (index ?i) (items $?items))
	?k <- (key (ch KEY_DOWN))
	=>
	(retract ?k)
	(modify ?m (index (mod (+ ?i 1) (length$ ?items)))))

(defrule move-up
	?m <- (menu (index ?i) (items $?items))
	?k <- (key (ch KEY_UP))
	=>
	(retract ?k)
	(modify ?m (index (mod (+ ?i (- (length$ ?items) 1)) (length$ ?items)))))

(defrule unknown-key
	?k <- (key (ch ?ch&~KEY_UP&~KEY_DOWN&~10))
	=>
	(retract ?k)
	(assert (key (ch (ncurses-key-to-str (ncurses-getch))))))

(defrule select-quit
	(menu (index ?i) (items $?items))
	(key (ch 10))
	(test (eq (nth$ (+ 1 ?i) ?items) "Quit"))
	=>
	(ncurses-endwin)
	(exit))

(reset)
(ncurses-initscr)
(ncurses-noecho)
(ncurses-cbreak)
(ncurses-keypad stdscr TRUE)
(ncurses-leaveok stdscr FALSE)
(ncurses-curs-set 0)
(run)
