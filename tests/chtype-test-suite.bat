; ============================================================
; CHTYPE
;
; A chtype is one integer holding a character, its attributes and its
; colour pair.  ncurses-chtype-character, -attributes and -color-pair take
; it apart, and inch is where a chtype comes from: it answers the whole
; cell, not just the character.
;
; The bit layout is ncurses' ABI -- eight bits of character, then eight
; bits of colour pair, then the attribute bits -- and has been since
; ncurses 5, so COLOR_PAIR(3) is 3 << 8 = 768 here.  The attribute bits
; are not spelled out: they are obtained by turning an attribute on and
; reading back what addch wrote with it.
; ============================================================

(fresh-screen)

; ------------------------------------------------------------
; a bare character
; ------------------------------------------------------------

(expect "the character of a plain A is A" 65 (ncurses-chtype-character 65))
(expect "it has no attributes" 0 (ncurses-chtype-attributes 65))
(expect "and no colour pair" 0 (ncurses-chtype-color-pair 65))

(expect "the character of 0 is 0" 0 (ncurses-chtype-character 0))
(expect "a space" 32 (ncurses-chtype-character 32))

; ------------------------------------------------------------
; the colour pair is the byte above the character
; ------------------------------------------------------------

(defglobal ?*ct-pair3* = (+ 65 768))

(expect "character survives a colour pair" 65 (ncurses-chtype-character ?*ct-pair3*))
(expect "the colour pair is 3" 3 (ncurses-chtype-color-pair ?*ct-pair3*))
(expect "the pair bits count as attributes, as A_ATTRIBUTES does in ncurses"
        768 (ncurses-chtype-attributes ?*ct-pair3*))

; ------------------------------------------------------------
; through the screen: addch stores the whole chtype and inch answers it
; ------------------------------------------------------------

(ncurses-move 1 1)
(expect "addch of a coloured A" OK (ncurses-addch ?*ct-pair3*))
(ncurses-move 1 1)
(expect "inch answers the whole cell" ?*ct-pair3* (ncurses-inch))
(expect "whose character is A" 65 (ncurses-chtype-character (ncurses-inch)))
(expect "and whose pair is 3" 3 (ncurses-chtype-color-pair (ncurses-inch)))

; ------------------------------------------------------------
; attributes, obtained rather than assumed
; ------------------------------------------------------------

(defglobal
  ?*ct-bold*      = 0
  ?*ct-underline* = 0)

(ncurses-attron A_BOLD)
(ncurses-move 2 1)
(ncurses-addch 66)
(ncurses-move 2 1)
(bind ?*ct-bold* (ncurses-chtype-attributes (ncurses-inch)))
(ncurses-attroff A_BOLD)

(ncurses-attron A_UNDERLINE)
(ncurses-move 3 1)
(ncurses-addch 66)
(ncurses-move 3 1)
(bind ?*ct-underline* (ncurses-chtype-attributes (ncurses-inch)))
(ncurses-attroff A_UNDERLINE)

(expect-true "a bold cell has attribute bits" (<> 0 ?*ct-bold*))
(expect-true "so does an underlined one" (<> 0 ?*ct-underline*))
(expect-true "and they are different bits" (<> ?*ct-bold* ?*ct-underline*))
(expect "the character under the attributes is still B" 66 (ncurses-chtype-character (ncurses-inch)))
(expect "attributes alone carry no colour pair" 0 (ncurses-chtype-color-pair (ncurses-inch)))

; a chtype built from the pieces takes apart into the same pieces
(defglobal ?*ct-all* = (+ 67 768 ?*ct-bold*))
(expect "character of the composite" 67 (ncurses-chtype-character ?*ct-all*))
(expect "pair of the composite" 3 (ncurses-chtype-color-pair ?*ct-all*))
(expect "attributes of the composite are the bold bits and the pair bits"
        (+ 768 ?*ct-bold*) (ncurses-chtype-attributes ?*ct-all*))

; addch takes the composite whole
(ncurses-move 4 1)
(ncurses-addch ?*ct-all*)
(ncurses-move 4 1)
(expect "and inch answers it whole" ?*ct-all* (ncurses-inch))
