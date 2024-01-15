# KDB Tetris

Usage:
```
q tetris.q (-q 1)

### MENU OPTIONS ###

[ENTER] = select menu option
[A] + [ENTER] = move curser to the left
[D] + [ENTER] = move cursor to the right

### IN GAME OPTIONS ###

[ENTER] = rotate clockwise
[SPACE] + [ENTER] = drop
[A] + [ENTER] = left
[D] + [ENTER] = right
[S] + [ENTER] = soft drop
[R] + [ENTER] = start/restart level
[X] + [ENTER] = return to main menu
```
KDB does not have an intuitive GUI and the updates rely on outputs to console, so depending on what software you are using the gameplay can be very janky. That being said, I've personally found that running this on windows batch is smoother than linux. I recommend quiet mode being enabled to suppress the `q)` prompt being shown.

The Tetrominoes and other elements also use characters from the IBM PC character set (Code Page 437). Windows and Linux read these in differently, and I have attempted to account for operating system version discrepancies. However, if you come across any issues with the encoding, please submit an issue.
