# CLIPSncurses

`ncurses` bindings for
[CLIPS](https://www.clipsrules.net/).

## Installation

```
git clone https://github.com/mrryanjohnston/CLIPSncurses
cd CLIPSncurses
make
```

You can then run the built executable and run the examples
in the `examples` dir by doing this:

```
./vendor/clips/clips -f2 examples/worms.bat
```

### Which CLIPS

`CLIPS_VERSION` selects the CLIPS source:

```
make                        # the 6.4.2 release tarball (the default)
make CLIPS_VERSION=svn-6x   # branches/64x of the CLIPS Subversion repository
make CLIPS_VERSION=svn-7x   # branches/70x
```

## Tests

```
make test
```

That builds, runs the suite in `tests/` against the build, and then runs
every example in `examples/`, feeding each the keys in the `.keys` file
beside it and checking that it reaches its own exit without writing to
stderr.  `make test-suite` and `make test-examples` run one half, and
`make test-all` runs the whole thing against all three CLIPS versions in
turn, which is what CI does across three runners.

ncurses draws on stdout and reads keys from stdin, so the suite is run
through `tests/run.sh`: it sends the screen to a file,
writes the suite's report to stderr, feeds a fixed sequence of key bytes on
stdin, and pins the terminal to xterm at 24x80 so the positions, key codes
and line-drawing characters asserted are the same on every machine.

## API

### `ncurses-initscr`

Determines the terminal type and initialises all implementation data structures.
Also causes the first refresh operation to clear the screen.

#### Returns

- `WINDOW *`: Pointer to `stdscr`

#### Example

```
(bind ?stdscr (ncurses-initscr))
```

### `ncurses-echo`
### `ncurses-noecho`

Controls whether characters typed by the user are echoed by getch as they are typed

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-echo)
(ncurses-noecho)
```

### `ncurses-cbreak`
### `ncurses-nocbreak`

Controls whether characters are buffered until a newline or carriage return is typed.
`ncurses-cbreak` disables line buffering and erase/kill character-processing
(interrupt and flow control characters are unaffected),
making characters typed by the user immediately available to the program.
`ncurses-nocbreak` returns the terminal to normal (cooked) mode. 

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-cbreak)
(ncurses-nocbreak)
```

### `ncurses-clear`

Copy blanks to every position in the window, clearing the screen. 
Also calls `clearok`, so that the screen is cleared completely
on the next call to `ncurses-wrefresh` for that window and repainted from scratch. 

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-clear)
```

### `ncurses-refresh`

Copies `stdscr` to the physical terminal screen,
taking into account what is already there to do optimizations.
Must be called to get actual output to the terminal
as other routines merely manipulate data structures.

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-refresh)
```

### `ncurses-endwin`

Restores the terminal after Curses activity
by at least restoring the saved shell terminal mode,
flushing any output to the terminal
and moving the cursor to the first column of the last line of the screen.
Refreshing a window resumes program mode.
The application must call `ncurses-endwin` for each terminal being used before exiting.
If `ncurses-newterm` is called more than once for the same terminal,
the first screen created must be the last one for which `ncurses-endwin` is called.

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-endwin)
```

### `ncurses-doupdate`

Flushes all pending screen changes to the terminal
in a single, efficient pass.

The key benefit over calling `ncurses-wrefresh` repeatedly is efficiency:
if you refresh multiple windows, each `ncurses-wrefresh` would hit the terminal immediately.
Using `ncurses-wnoutrefresh` + `ncurses-doupdate` batches all updates into one terminal write,
reducing flicker and I/O overhead.

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-doupdate)
```

### `ncurses-start-color`

Enables the use of colors in an ncurses program.

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-initscr)
(ncurses-start-color)

(ncurses-init-pair 1 COLOR_RED COLOR_BLACK)
(ncurses-init-pair 2 COLOR_GREEN COLOR_BLACK)
(ncurses-init-pair 3 COLOR_YELLOW COLOR_BLACK)

(ncurses-attron (ncurses-color-pair 1))
(ncurses-addstr "This text is red!")
(ncurses-attroff (ncurses-color-pair 1))

(ncurses-attron (ncurses-color-pair 2))
(ncurses-addstr "\nThis text is green!")
(ncurses-attroff (ncurses-color-pair 2))

(ncurses-refresh)
(ncurses-getch)
(ncurses-endwin)
```

### `ncurses-keypad`

Enables usage of function keys, arrow keys, numeric keypad
as single key events.

#### Arguments

- `WINDOW *`: Window pointer or the symbol `stdscr`
- `BOOLEAN`: Either `TRUE` or `FALSE` to set `leaveok`

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-initscr)
(ncurses-keypad stdscr TRUE)
(ncurses-noecho)

(bind ?ch (ncurses-getch))

(if (= ?ch KEY_UP) then
    (ncurses-addstr "You pressed the UP arrow!")
elif (= ?ch KEY_DOWN) then
    (ncurses-addstr "You pressed the DOWN arrow!")
elif (= ?ch KEY_LEFT) then
    (ncurses-addstr "You pressed the LEFT arrow!")
elif (= ?ch KEY_RIGHT) then
    (ncurses-addstr "You pressed the RIGHT arrow!")
else
    (ncurses-addstr "You pressed some other key.")
)

(ncurses-refresh)
(ncurses-getch)
(ncurses-endwin)
```

### `ncurses-leaveok`

By default (`FALSE`), after a call to `ncurses-wrefresh` or `ncurses-refresh`,
the physical terminal cursor is moved to the position of the window's logical cursor.
If you run `(ncurses-leaveok ?window TRUE)`,
the physical cursor is left at whatever position the update process happened to leave it;
ncurses avoids the extra cursor motion to the logical cursor location.

#### Arguments

- `WINDOW *`: Window pointer or the symbol `stdscr`
- `BOOLEAN`: Either `TRUE` or `FALSE` to set `leaveok`

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-leaveok stdscr TRUE)
```

### `ncurses-curs-set`

Sets visibility of the cursor

#### Arguments

- `0` or `INVISIBLE`
- `1` or `VISIBLE`
- `2` or `HIGHLY-VISIBLE`

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

### `ncurses-move`

Move the cursor on `stdscr` relative to the top left corner of the terminal.
Must call `ncurses-refresh` after calling `ncurses-move` to actually move it.

#### Arguments

- `y`: `y` position (vertical) from top left corner
- `x`: `x` position (horizontal) from top left corner

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Example

```
(ncurses-move 21 65)
(ncurses-refresh)
```

### `ncurses-mvprintw`

Move the cursor relative to the top left corner of stdscr
and prints the string to the window.
Must call `ncurses-refresh` to actually move and write the text.

#### Arguments

- `y`: `y` position (vertical) from top left corner
- `x`: `x` position (horizontal) from top left corner
- `STRING`: The text to write

### `ncurses-mvwprintw`

Move the cursor relative to the top left corner of the specified window
and prints the string to the window.
Must call `ncurses-refresh` to actually move and write the text.

#### Arguments

- `WINDOW *`: Window pointer or the symbol `stdscr`
- `y`: `y` position (vertical) from top left corner
- `x`: `x` position (horizontal) from top left corner
- `STRING`: The text to write

### `ncurses-getch`

Read a single character of input from the keyboard in a terminal-independent manner.

#### Returns

`SYMBOL`: any named special key like `KEY_UP`, `KEY_DOWN`, `KEY_MOUSE`, `KEY_RESIZE`, function keys like `KEY_F(1)`, `KEY_F(2)`, and so on, or a single-character in the printable ASCII character range 32-126 (space through ~).
`INTEGER`: control characters (0–31), DEL (127), and any key code that isn't a printable ASCII char, isn't a named special key, and isn't a function key. Essentially the raw ncurses int falls through as-is.

#### Example

```
(ncurses-getch)
```

### `ncurses-inch`

Return the character at the current position in the named window.
Use in combincation with `ncurses-chtype-character`, `ncurses-chtype-attributes`, and `ncurses-chtype-color-pair`
to get the character, attributes, and color-pair respectively
from the returned `chtype`.

#### Returns

An `INTEGER` representing the ncurses `chtype`,
an integral data type used to store a single 8-bit character
combined with its associated display attributes in a single variable.

### `ncurses-border`

Draws a border around `stdscr`.

#### Arguments

8 `chtype`s that can be of the form
`INTEGER`, `MULTIFIELD`, or `SYMBOL`:

- `ls` (default `ACS_VLINE`): Starting-column side
- `rs` (default `ACS_VLINE`): Ending-column side
- `ts` (default `ACS_HLINE`): First-line side
- `bs` (default `ACS_HLINE`): Last-line side
- `tl` (default `ACS_ULCORNER`): Corner of the first line and the starting column
- `tr` (default `ACS_URCORNER`): Corner of the first line and the ending column
- `bl` (default `ACS_LLCORNER`): Corner of the last line and the starting column
- `br` (default `ACS_LRCORNER`): Corner of the last line and the ending column

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-border 0 0 0 0 0 0 0 0)
(ncurses-border | | - - + + + +)
(ncurses-border ACS_VLINE ACS_VLINE ACS_HLINE ACS_HLINE
                ACS_ULCORNER ACS_URCORNER ACS_LLCORNER ACS_LRCORNER)
(ncurses-border 124 124 45 45 43 43 43 43)
(ncurses-border (create$ ACS_VLINE A_NORMAL 1) (create$ ACS_VLINE A_NORMAL 1)
                (create$ ACS_HLINE A_NORMAL 1) (create$ ACS_HLINE A_NORMAL 1)
                (create$ ACS_ULCORNER A_NORMAL 1) (create$ ACS_URCORNER A_NORMAL 1)
                (create$ ACS_LLCORNER A_NORMAL 1) (create$ ACS_LRCORNER A_NORMAL 1))
```

### ncurses-wborder

Draws a border around the specified window.

#### Arguments

- `WINDOW *`: A window to set the border for

8 `chtype`s that can be of the form
`INTEGER`, `MULTIFIELD`, or `SYMBOL`:

- `ls` (default `ACS_VLINE`): Starting-column side
- `rs` (default `ACS_VLINE`): Ending-column side
- `ts` (default `ACS_HLINE`): First-line side
- `bs` (default `ACS_HLINE`): Last-line side
- `tl` (default `ACS_ULCORNER`): Corner of the first line and the starting column
- `tr` (default `ACS_URCORNER`): Corner of the first line and the ending column
- `bl` (default `ACS_LLCORNER`): Corner of the last line and the starting column
- `br` (default `ACS_LRCORNER`): Corner of the last line and the ending column

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-wborder ?win 0 0 0 0 0 0 0 0)
(ncurses-wborder ?win | | - - + + + +)
(ncurses-wborder stdscr ACS_VLINE ACS_VLINE ACS_HLINE ACS_HLINE
                ACS_ULCORNER ACS_URCORNER ACS_LLCORNER ACS_LRCORNER)
(ncurses-wborder stdscr 124 124 45 45 43 43 43 43)
(ncurses-wborder ?win (create$ ACS_VLINE A_NORMAL 1) (create$ ACS_VLINE A_NORMAL 1)
                (create$ ACS_HLINE A_NORMAL 1) (create$ ACS_HLINE A_NORMAL 1)
                (create$ ACS_ULCORNER A_NORMAL 1) (create$ ACS_URCORNER A_NORMAL 1)
                (create$ ACS_LLCORNER A_NORMAL 1) (create$ ACS_LRCORNER A_NORMAL 1))
```

	,"b",3,3,"ly;ey",NcursesboxFunction,"NcursesboxFunction",NULL);

### ncurses-box

Draws borders. Is a shorthand for `(ncurses-wborder win verch verch horch horch 0 0 0 0)`

#### Arguments

- `WINDOW *`: A window to set the border for
- `verch`: Vertical border character 
- `horch`: Horizontal border character 

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-box stdscr 0 0)
```

### ncurses-newwin

Creates and returns a pointer to a new window with the given number of lines and columns

#### Arguments

- `nlines`
- `ncols`
- `begin_y`
- `begin_x`

#### Returns

A `WINDOW *` to the newly created window

#### Examples

```
(ncurses-newwin 20 16 0 64)
```

### ncurses-wclear

#### Arguments

- `WINDOW *`: A window to clear

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-wclear stdscr)
```

### ncurses-wrefresh

#### Arguments

- `WINDOW *`: A window to refresh

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-wrefresh stdscr)
```

### ncurses-addch

#### Arguments

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-addch 32)
```

### ncurses-chtype-character

#### Arguments

- `chtype`

#### Returns

- The chtype's character's ascii code

#### Example

```
(ncurses-chtype-character ?chtype)
```

### ncurses-chtype-attributes

#### Arguments

- `chtype`

#### Returns

- The chtype's attributes

#### Example

```
(ncurses-chtype-attributes ?chtype)
```

### ncurses-chtype-color-pair

#### Arguments

- `chtype`

#### Returns

- The chtype's color pair

#### Example

```
(ncurses-chtype-color-pair ?chtype)
```

### ncurses-timeout

Set the timeout

#### Arguments

- `delay`

#### Returns

- `TRUE` on success

#### Examples

```
(ncurses-timeout (+ 200 (integer (* 1000 (time)))))))
```

### ncurses-wtimeout

Set the timeout for a specific window

#### Arguments

- `WINDOW *`: A window to refresh
- `delay`

#### Returns

- `TRUE` on success

#### Examples

```
(ncurses-wtimeout ?window (+ 200 (integer (* 1000 (time)))))))
```

### ncurses-getyx

#### Arguments

- `WINDOW *`: A window to refresh

#### Returns

- `y` and `x` coordinates in a `MULTIFIELD`

#### Examples

```
(ncurses-getyx ?window)
```

### ncurses-getmaxyx

#### Arguments

- `WINDOW *`: A window to refresh

#### Returns

- `y` and `x` coordinates in a `MULTIFIELD`

#### Examples

```
(ncurses-getyx ?window)
```

### ncurses-delwin

#### Arguments

- `WINDOW *`: A window to refresh

#### Returns

- `OK` if successful
- `ERR` if ncurses returned an error
- `FALSE` if some other error happened

#### Examples

```
(ncurses-delwin ?window)
```

### ncurses-attron

### ncurses-attroff
