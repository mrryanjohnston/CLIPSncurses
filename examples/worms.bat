;(dribble-on logs)
;(watch all)
; Based on
; https://www.paulgriffiths.net/program/c/srcs/curwormsrc.html
(defglobal
	?*wormbit* = 79 ; O
	?*wormfood* = 88 ; X
	?*empty* = 32) ; SPACE

(deftemplate worm
	(slot x (default 1))
	(slot y (default 8))
	(slot x-delta (default 0) (allowed-values -1 0 1))
	(slot y-delta (default 1) (allowed-values -1 0 1))
	(multislot x-trail (default 1 1 1 1 1 1 1))
	(multislot y-trail (default 1 2 3 4 5 6 7))
	(slot last-x (default 1))
	(slot last-y (default 2)))

(deftemplate food
	(slot x)
	(slot y))

(deffunction draw-worm (?worm)
	(ncurses-move
		(fact-slot-value ?worm last-y)
		(fact-slot-value ?worm last-x))
	(ncurses-addch ?*empty*)
	(ncurses-move
		(fact-slot-value ?worm y)
		(fact-slot-value ?worm x))
	(ncurses-addch ?*wormbit*)
	(loop-for-count (?cnt 1 (length$ (fact-slot-value ?worm x-trail)))
		(ncurses-move
			(nth$ ?cnt (fact-slot-value ?worm y-trail))
			(nth$ ?cnt (fact-slot-value ?worm x-trail)))
		(ncurses-addch ?*wormbit*)))

(deffunction draw-food (?food)
	(ncurses-move (fact-slot-value ?food y) (fact-slot-value ?food x))
	(ncurses-addch ?*wormfood*))

(deffunction place-food (?y ?x)
	(bind ?food (assert (food (x (random 2 ?x)) (y (random 2 ?y)))))
	(ncurses-move (fact-slot-value ?food y) (fact-slot-value ?food x))
	(while (<> 32 (ncurses-chtype-character (ncurses-inch)))
		(retract ?food)
		(bind ?food (assert (food (x (random 2 ?x)) (y (random 2 ?y)))))
		(ncurses-move (fact-slot-value ?food y) (fact-slot-value ?food x))))
(deffunction x-y-in-trail (?x ?y ?x-trail ?y-trail)
	(loop-for-count (?cnt 1 (length$ ?x-trail)) do
		(if (and (= ?x (nth$ ?cnt ?x-trail)) (= ?y (nth$ ?cnt ?y-trail))) then
			(return TRUE))))
(deffacts initialize
	(mainwin (ncurses-initscr))
	(oldcur (ncurses-curs-set 0))
	(worm)
	(score 0))

(defrule init
	(mainwin ?mainwin)
	=>
	(ncurses-noecho)
	(ncurses-keypad ?mainwin TRUE)
	(ncurses-box stdscr 0 0)
	(assert
		(initialized)
		(screen-size (ncurses-getmaxyx ?mainwin))
		(next-timeout (+ 200 (integer (* 1000 (time)))))))

(defrule draw-worm
	(initialized)
	?w <- (worm (x ?x) (y ?y))
	=>
	(draw-worm ?w)
	(assert (worm-drawn)))

(defrule place-food
	(screen-size ?y ?x)
	(worm-drawn)
	(not (food))
	=>
	(place-food (- ?y 1) (- ?x 1)))

(defrule draw-food
	(initialized)
	?f <- (food (x ?x) (y ?y))
	=>
	(draw-food ?f)
	(assert (food-drawn)))

(defrule detect-key-press
	(worm-drawn)
	(food-drawn)
	(next-timeout ?timeout)
	(not (getch ?))
	=>
	(ncurses-timeout (- ?timeout (integer (* 1000 (time)))))
	(assert (getch (ncurses-key-to-str (ncurses-getch)))))

(defrule detect-q
	(mainwin ?mainwin)
	(oldcur ?oldcur)
	(score ?score)
	(getch q)
	=>
	(ncurses-delwin ?mainwin)
	(ncurses-curs-set ?oldcur)
	(ncurses-endwin)
	(println "You quit!")
	(println "Your score is " ?score)
	(exit))

(defrule detect-up
	?w <- (worm (x-delta ~0))
	?g <- (getch KEY_UP)
	?wd <- (worm-drawn)
	=>
	(retract ?g)
	(modify ?w (x-delta 0) (y-delta -1)))

(defrule detect-down
	?w <- (worm (x-delta ~0))
	?g <- (getch KEY_DOWN)
	?wd <- (worm-drawn)
	=>
	(retract ?g)
	(modify ?w (x-delta 0) (y-delta 1)))

(defrule detect-right
	?w <- (worm (y-delta ~0))
	?g <- (getch KEY_RIGHT)
	?wd <- (worm-drawn)
	=>
	(retract ?g)
	(modify ?w (y-delta 0) (x-delta 1)))

(defrule detect-left
	?w <- (worm (y-delta ~0))
	?g <- (getch KEY_LEFT)
	?wd <- (worm-drawn)
	=>
	(retract ?g)
	(modify ?w (y-delta 0) (x-delta -1)))

(defrule eat-food
	?w <- (worm (x ?x) (y ?y) (x-delta ?x-delta) (y-delta ?y-delta) (x-trail $?x-trail) (y-trail $?y-trail))
	?wd <- (worm-drawn)
	?f <- (food (x =(+ ?x ?x-delta)) (y =(+ ?y ?y-delta)))
	?fd <- (food-drawn)
	?s <- (score ?score)
	?g <- (getch -1)
	?t <- (next-timeout ?)
	=>
	(retract ?wd ?f ?fd ?s ?g ?t)
	(modify ?w
		(x (+ ?x-delta ?x))
		(y (+ ?y-delta ?y))
		(x-trail ?x-trail ?x)
		(y-trail ?y-trail ?y))
	(assert (score (+ 10 ?score))))

(defrule advance-frame
	(screen-size ?max-y ?max-x)
	?w <- (worm (x ?x) (y ?y) (x-delta ?x-delta) (y-delta ?y-delta) (x-trail $?x-trail) (y-trail $?y-trail))
	?wd <- (worm-drawn)
	(food (x ?fx) (y ?fy))
	(food-drawn)
	?s <- (score ?score)
	?g <- (getch -1)
	?t <- (next-timeout ?)
	(or (test (<> ?fx (+ ?x ?x-delta))) (test (<> ?fy (+ ?y ?y-delta))))
	(test (not (x-y-in-trail (+ ?x ?x-delta) (+ ?y ?y-delta) ?x-trail ?y-trail)))
	(test (> (+ ?x ?x-delta) 0))
	(test (> (+ ?y ?y-delta) 0))
	(test (< (+ ?x ?x-delta) ?max-x))
	(test (< (+ ?y ?y-delta) ?max-y))
	=>
	(retract ?wd ?s ?g ?t)
	(modify ?w
		(x (+ ?x-delta ?x))
		(y (+ ?y-delta ?y))
		(x-trail (rest$ ?x-trail) ?x)
		(y-trail (rest$ ?y-trail) ?y)
		(last-x (nth$ 1 ?x-trail))
		(last-y (nth$ 1 ?y-trail)))
	(assert (score (+ 1 ?score))))

(defrule hit-wall
	(mainwin ?mainwin)
	(oldcur ?oldcur)
	(screen-size ?max-y ?max-x)
	(worm (x ?x) (y ?y) (x-delta ?x-delta) (y-delta ?y-delta) (x-trail $?x-trail) (y-trail $?y-trail))
	(worm-drawn)
	(food (x ?fx) (y ?fy))
	(food-drawn)
	(score ?score)
	(getch -1)
	(next-timeout ?)
	(or
		(test (<= (+ ?x ?x-delta) 0))
		(test (<= (+ ?y ?y-delta) 0))
		(test (>= (+ ?x ?x-delta) ?max-x))
		(test (>= (+ ?y ?y-delta) ?max-y)))
	=>
	(ncurses-delwin ?mainwin)
	(ncurses-curs-set ?oldcur)
	(ncurses-endwin)
	(println "You hit a wall!")
	(println "Your score is " ?score)
	(exit))

(defrule hit-self
	(mainwin ?mainwin)
	(oldcur ?oldcur)
	(screen-size ?max-y ?max-x)
	(worm (x ?x) (y ?y) (x-delta ?x-delta) (y-delta ?y-delta) (x-trail $?x-trail) (y-trail $?y-trail))
	(worm-drawn)
	(food (x ?fx) (y ?fy))
	(food-drawn)
	(score ?score)
	(getch -1)
	(next-timeout ?)
	(test (x-y-in-trail (+ ?x ?x-delta) (+ ?y ?y-delta) ?x-trail ?y-trail))
	=>
	(ncurses-delwin ?mainwin)
	(ncurses-curs-set ?oldcur)
	(ncurses-endwin)
	(println "You hit yourself!")
	(println "Your score is " ?score)
	(exit))

(defrule determine-next-timeout
	(not (next-timeout ?))
	=>
	(assert
		(next-timeout (+ 200 (integer (* 1000 (time)))))))

(defrule clean-up
	(declare (salience -1))
	?g <- (getch ~-1)
	=>
	(retract ?g))

(seed (integer (* 1000 (time))))
(reset)
(run)
