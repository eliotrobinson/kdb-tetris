/ [ENTER] = rotate clockwise
/ [SPACE] + [ENTER] = drop
/ [A] + [ENTER] = left
/ [D] + [ENTER] = right
/ [S] + [ENTER] = soft drop
/ [N] + [ENTER] = start/restart game
/ [X] + [ENTER] = exit

if[.op.win:.z.o like"w*";system"echo 1"];                                                       / check if the operating system is windows, if so call a system command to avoid colours bugs
if[.op.lin:.z.o like"l*";];                                                                     / check if the operating system is linux, do nothing but keep the if in case
if[all not .op`win`lin;-1"Unrecognised Operating System";exit 1];                               / if neither are true, then exit due to an untested operating system being used

.op.b:("\342\226\210";"\333").op.win;                                                           / the code for █ differs in windows and linux, and causes headaches later on
.op.o:0 2 .op.win;                                                                              / since the code for █ either has 3 or 1 characters, we will need to offset some strings
.op.rows:$[.op.win;50;"J"$first system"tput lines"];                                            / use tput to get the window height, and just guess for windows since nothing similar exists
.op.cols:$[.op.win;"J"$trim 12_system["mode con"]4;first"J"$system"tput cols"];                 / use tput to get the window width, and use mode con if using windows
.op.sleep:$[.op.lin;                                                                            / some effects utilise the operating systems sleep function
  {system"sleep ",string x};                                                                    / for linux, easily use sleep
  {do[floor x*10;@[system;"ping 192.0.2.2 -n 1 -w 0.1 > nul";{x;}]]}                            / for windows, use ping on a non existent address to sleep for 1ms, then repeat x time
 ];                                                                                             /   cant use TIMEOUT since it only accepts seconds
                                                                                                /   and ping waits at least 500ms if anything above -w 1 is used HEADACHE :(

system"S ",-5#string .z.p;                                                                      / get a random seed based on current time
system"c ",string[2+.op.rows]," 500";                                                           / set the console size based on the current window size

.state.pos:(!/)flip 2 cut                                                                       / make a dictionary for all shapes centered on an index of (0;0), this is also used for
 (`I  ;4#((-1 0;0 0;1 0;2 0);(-1 -1;-1 0;-1 1;-1 2));                                           / rotation purposes which is why four sets of indexes exist for each shape
  `O  ;4#enlist(-1 -1;-1 0;0 -1;0 0);
  `J  ;((0 -1;0 0;0 1;1 1);(-1 0;0 0;1 0;1 -1);(-1 -1;0 -1;0 0;0 1);(-1 1;-1 0;0 0;1 0));
  `L  ;((0 -1;0 0;0 1;1 -1);(-1 -1;-1 0;0 0;1 0);(-1 1;0 -1;0 0;0 1);(-1 0;0 0;1 0;1 1));
  `T  ;((0 -1;0 0;0 1;1 0);(-1 0;0 -1;0 0;1 0);(-1 0;0 -1;0 0;0 1);(-1 0;0 0;0 1;1 0));
  `S  ;4#((0 0;0 1;1 -1;1 0);(-1 -1;0 -1;0 0;1 0));
  `Z  ;4#((0 -1;0 0;1 0;1 1);(-1 0;0 -1;0 0;1 -1)));

.state.colours:(!/)flip 2 cut                                                                   / make a dictionary of all shapes to colours, this is basic atm but can be expanded later
 (`I  ;`$"\033[36m",.op.b,"\033[0m";
  `O  ;`$"\033[33m",.op.b,"\033[0m";
  `J  ;`$"\033[34m",.op.b,"\033[0m";
  `L  ;`$"\033[29m",.op.b,"\033[0m";
  `T  ;`$"\033[35m",.op.b,"\033[0m";
  `S  ;`$"\033[32m",.op.b,"\033[0m";
  `Z  ;`$"\033[31m",.op.b,"\033[0m";
  `B  ;`$"\033[30m",.op.b,"\033[0m";
  `G  ;`$"\033[37m",.op.b,"\033[0m");

.state.gravity:`s#(til[11],13 16 19 29)!48 43 38 33 28 23 18 13 8 6 5 4 3 2 1;                  / make a step dictionary for the falling speeds (gravity) for each level(s)

print_screen:{                                                                                  / function for printing the screen based on the current grid
  r:(raze/')string 2#''x;                                                                       / since a block █ is quite thin, expand it to make a square ██
  r:@[r;3 4;,;-9$("SCORE";string .state.score)];                                                / append the current score on the 2nd and 3rd row
  r:@[r;6 7;,;-9$("LEVEL";string .state.level)];                                                / append the current level on on the 5th and 6th row
  r:@[r;9 10;,;-9$("LINES";string .state.lines)];                                               / append the current lines cleared on the 8th and 9th row
  r:@[r;12 13 14 15 16;,;(raze/')string 2#''.state.np_grid];                                    / below the lines, display the next piece, this piece has there own little grid
  if[.state.game_end;r:gen_end_screen r];                                                       / if the game end is triggered, overlay the game end message
  -1{z[0],(y,/:x),z 1}[r]..state`h_offset`v_offset;                                             / add the horizontal and vertical offsets to make the grid central
 };

gen_end_screen:{                                                                                / if the game has ended, add the overlay to the current grid
  f:{[o;i;m;x]raze@[(12-o)cut x;i;:;m]}.op.o;                                                   / define the function to help, this is awkward since the blocks have 10/12 characters
  r:@[x;5 19;f[i;string .state.colours count[i:4+til 16]#`G]];                                  / make top and bottom borders
  r:@[r;6+til 13;f[4+til 16;string .state.colours`$'"GG",(12#"B"),"GG"]];                       / make left and right borders
  r:@[r;7;f[7 8 9 10 12 13 14 15;"GAMEOVER"]];                                                  / assign GAME OVER at the top of the box
  r:@[r;8;f[7 8 9 10 11 12;"PLEASE"]];                                                          / assign PLEASE below
  r:@[r;10;f[8 9 10;"TRY"]];                                                                    / assign TRY below that
  r:@[r;11;f[9 10 11 12 13 15;("A";"G";"A";"I";"N";("\342\231\245";"\003").op.win)]];           / assign AGAIN ♥ below that, again awkward because the heart has 3/1 characters
  r:@[r;13;f[7 8 9 10 11 13 15 16;"PressNto"]];                                                 / from here on, simply assign text to appropriate rows and cols
  r:@[r;14;f[7 8 10 11 13 14 15 16;"gotomenu"]];
  r:@[r;16;f[7 8 9 10 11 13 15 16;"PressXto"]];
  :@[r;17;f[7 8 9 10;"exit"]];
 };

new_piece:{                                                                                     / if the last piece has dropped and the game has not ended, we need to create a new piece
  .state.piece:.state.next_piece;                                                               / assign the next piece to the current piece
  .state.orientation:.state.next_orientation;                                                   / assign the orientation of the next piece as the current orientation
  .state.next_piece:`$1?"IOJLTZS";                                                              / randomly choose what the next piece will be
  .state.next_orientation:1?0 1 2 3;                                                            / randomly choose at what orientation the next piece will be
  .state.np_grid:next_piece_grid . .state`next_piece`next_orientation;                          / create the grid for the next piece to be displayed below the scores
  .state.centre:1 6;                                                                            / reset the centre of the piece for rotation purposes
  .state.active:{[po;pi;o;e]e+/:raze po[pi]o}. .state`pos`piece`orientation`centre;             / assign the active piece indexes
  drop_piece[];                                                                                 / drop the piece so that it is immediately on the grid
 };

next_piece_grid:{[np;no]                                                                        / much like the main tetris grid, this function generates the image of the next piece
  .state.np_grid:5#enlist 5#.state.colours`B;                                                   / reset the smaller 5x5 grid to generate the image on
  n:2 2+/:raze .state.pos[np]no;                                                                / with (2;2) as the centre, assign the indexes where the piece will sit
  .[`.state.np_grid;;:;.state.colours np]each n;                                                / fill in those indexes with the appropriate coloured block
  .state.np_grid                                                                                / return the next piece grid
 };

drop_piece:{                                                                                    / this function drops the piece to the next available free space after a set time
  .[`.state.grid;;:;.state.colours`B]each .state.active;                                        / remove the coloured blocks from the active piece from the grid
  .state.active:.state.active+\:1 0;                                                            / drop the active indexes down a row
  .state.centre:.state.centre+1 0;                                                              / drop the centre of the active indexes down a row too
  if[any .state.colours[`B]<>.state.grid ./:.state.active;                                      / are all the spaces the new indexes taking up black? if not:
    .state.active:.state.active+\:-1 0;                                                         /   take the indexes back up a row
    if[0 in .state.active[;0];game_over[];:()];                                                 /   are the original indexes part of the top row? if so the game is over
    .[`.state.grid;;:;.state.colours .state.piece]each .state.active;                           /   otherwise, the piece is locked in and is reassigned the the grid
    if[any r:all each .state.colours[`B]<>-21#-1_.state.grid;row_complete r];                   /   are any rows complete? if so, we need to get rid of them
    new_piece[];                                                                                /   once the check is complete, we can generate a new piece and begin dropping it again
    :();                                                                                        /   finally leave early
  ];
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;                             / all the spaces below were black, and the piece just drops a row, assign it to the grid
  print_screen .state.grid;                                                                     / output the current state to console
 };

row_complete:{                                                                                  / this runs if 1 or more rows are full, we need to get rid of them and add up scores
  .state.game_started:0b;                                                                       / replicate the menu state to disable all key inputs, otherwise the new block can be moved
  c:@[.state.grid;w;:;e:count[w:1+where x]#enlist {x,(10#y),x}..state.colours`G`B]; / make a copy of the grid where the completed rows are replaced with blank rows
  do[3;                                                                                         / a naughty way of making the rows that are completed flash
    print_screen c;                                                                             / output the screen with the blank rows to console
    .op.sleep 0.2;                                                                              / wait for 0.2 seconds
    print_screen .state.grid;                                                                   / output the screen with the completed rows to console
    .op.sleep 0.2;                                                                              / wait again for 0.2 seconds, and do it 3 times
  ];
  .state.grid:c;                                                                                / update the grid to be that with the blank rows
  {.state.grid:.state.grid _ x}each desc w;                                                     / starting at the top row, drop it from the grid
  pad:enlist 12#enlist`;                                                                        / pad out the rows above the game screen with nothingness
  .state.grid:pad,e,1 _ .state.grid;                                                            / join the padding, the blank rows we took out, and grid together. seems hacky but it works
  .state.lines+:sum x;                                                                          / update the lines completed
  .state.score+:(1 2 3 4i!40 100 300 1200*.state.level+1)sum x;                                 / update the score BEFORE the level, since the rows were completed on the previous level
  .state.level:.state.lines div 10;                                                             / then safely update the levels (can make something smarter than levelling up every 10 lines)
  .state.game_started:1b;                                                                       / re-enable all key inputs
 };

game_over:{                                                                                     / if the game is over, we want to stop everything and finalise the grid
  .state.game_end:1b;                                                                           / set the state to game end, so that the appropriate game end screen is displayed
  .[`.state.grid;;:;.state.colours .state.piece]each 1 0+/:.state.active;                       / drop the current piece anyway and set it to the grid (like the nes version)
  print_screen .state.grid;                                                                     / print the screen with the game end message to the console
  system"t 0";                                                                                  / pause .z.ts so nothing else happens
 };                                                                                             / we dont need to disable inputs here since all game end user inputs will be evaluated

new_game:{                                                                                      / function to create a fancy title screen
  .state.game_started:0b;                                                                       / set the state to game not started, so no movement inputs can be evaluated
  .state.game_end:0b;                                                                           / also set/reset to game not ended, so no movement inputs can be evaluated also
  l1:"BTTTTTBOOOOOBJJJJJBZZZZBBIIIBBSSSSB";                                                     / make the fancy tetris logo, if you look hard enough you can see it in the text!
  l2:"BBBTBBBOBBBBBBBJBBBZBBBZBBIBBSBBBBB";
  l3:"BBBTBBBOOOOBBBBJBBBZZZZBBBIBBBSSSBB";
  l4:"BBBTBBBOBBBBBBBJBBBZBBZBBBIBBBBBBSB";
  l5:"BBBTBBBOOOOOBBBJBBBZBBBZBIIIBSSSSBB";
  logo:(raze/')string 2#''.state.colours`$''(l1;l2;l3;l4;l5);                                   / convert the text strings to their colours blocks and join them
  i:("";"";"   Press N to start a new game                      Press X to exit");              / add a couple of empty lines followed by the menu options
  c:("";"";"                            ",("\302\251";"\270")[.op.win]," 1989 Nintendo");       / add a couple of empty lines followed by the copyright info, getting right code from os
  v_pad:div[-10+.op.rows;2];                                                                    / allocate padding to put above and below the logo, so as it is central
  h_pad:floor[(.op.cols-70)%2]#" ";                                                             / allocate padding to put in front of the logo to make it in the middle of the screen
  -1 ((v_pad+5)#enlist""),(h_pad,/:logo,i,c),(v_pad-5)#enlist"";                                / join them all together and output it to the console
 };

/ logo is 70 characters wide

move:{                                                                                          / the move user input, this moves the active piece either left or right
  .[`.state.grid;;:;.state.colours`B]each .state.active;                                        / remove the active piece from the grid
  if[c:all .state.colours[`B]=.state.grid ./:(n:.state.active+\:0,x)except .state.active;       / move the active indexes left/right, and check if all spaces are empty, ignoring itself
    .state.active:n;                                                                            / if they are all empty then we can assign the new indexes to the active piece
    .state.centre:.state.centre+0,x;                                                            / like wise, move the centre to the left or right
  ];
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;                             / either way, assign the the new/old indexes to the grid if movement was possible or not
  if[c;print_screen .state.grid];                                                               / output the new grid to the console if movement did occur, eases load on users eyes
 };

slam:{                                                                                          / the hard drop user input, this drops the piece as low as it can possibly go
  .[`.state.grid;;:;.state.colours`B]each .state.active;                                        / remove the active piece from the grid
  b:.state.grid ./:/:.state.active+/:\:til[23],'0;                                              / get a list of all blocks for each column under the blocks of the active piece
  .state.active:.state.active+\:min[-1+min each where each .state.colours[`B]<>b],0;            / for each column, get the highest available free index, and take the highest of them all
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;                             / reassign the new indexes of the active piece back to the grid
  print_screen .state.grid;                                                                     / output the new grid to the console
  if[any r:all each .state.colours[`B]<>-21#-1_.state.grid;row_complete r];                     / since this automatically ends the active pieces movements, check if any rows are cleared
  new_piece[];                                                                                  / and move onto the next piece
 };

rotate_piece:{                                                                                  / the rotate user input, this rotates the piece clockwise in true nes fashion
  .[`.state.grid;;:;.state.colours`B]each .state.active;                                        / remove the active piece from the grid
  o:mod[;4].state.orientation+1;                                                                / make a place holder for the new orientation
  n:{[o;po;pi;e]e+/:raze po[pi]o}[o]. .state`pos`piece`centre;                                  / make a place holder for the new indexes of the active piece after rotation
  if[c1:not any .state.colours[`B]<>.state.grid ./:n;                                           / are the potential new indexes empty?  TODO - implement wall kick
    .state.active:n;                                                                            /   if so, assign the place holder indexes as the active indexes
    .state.orientation:o;                                                                       /   and the place holder orientation and the current orientation
  ];
  if[c2:any wk:(2 cut .state.colours`G`B`B`G)~\:2#distinct i:.state.grid ./:n;                  / we might be able to wall kick, check if the new indexes are either a wall and nothing else
    wk:first where wk;                                                                          /   are we by the left or right wall
    i:({1};{max[x]-10})[wk]n[;1];                                                               /   check how much we should kick away, noting that the right wall is dynamic due to flat I
    n:n+\:i:0,(::;neg)[wk]i;                                                                    /   get the new indexes after the wall kick to the left/right
    if[c2:all .state.colours[`B]=.state.grid ./:n;                                              /   need to check again if the new indexes are all black
      .state.active:n;                                                                          /     if so, assign the new indexes to the active piece
      .state.orientation:o;                                                                     /     and assign the new orientation
      .state.centre:.state.centre+i;                                                            /     dont forget the centre has also moved, so adjust this too
    ];
  ];
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;                             / reassign the the active piece back to the grid
  if[c1|c2;print_screen .state.grid];                                                           / output the new grid to the console if movement did occur, eases load on users eyes
 };

.z.pi:{                                                                                         / this function handles all user inputs, where x is the key press like "a \n"
  if[.state.game_end;$[x like"[nN]*";new_game[];x like"[xX]*";exit 0;::];:()];                  / if we are on the end screen, have the user return to menu or exit, and nothing else
  if[not .state.game_started;$[x like"[nN]*";start[];x like"[xX]*";exit 0;::];:()];             / if we are on the menu screen, have the user start a new game or exit, and nothing else
  $[                                                                                            / if we are not on the menu or end screen, we must be in the game
    x like"[aA]*";move -1;                                                                      / if the user pressed a, then move the active pieve to the left
    x like"[dD]*";move 1;                                                                       / if the user pressed d, then move the active piece to the right
    x like"[sS]*";drop_piece[];                                                                 / if the user pressed s, we want to softly drop the active piece (more for debugging)
    x like"[xX]*";exit 0;                                                                       / if the user pressed x, exit the game
    x like"[nN]*";start[];                                                                      / if the user pressed n, restart the game (more for debugging)
    x like" *";slam[];                                                                          / if the user pressed the space bar, hard drop the active pieve
    rotate_piece[]                                                                              / if anything else/nothing was entered and enter was hit, rotate the active piece clockwise
  ];
 };

.z.ts:{                                                                                         / the timer of which the game functions and updates, this function will be executed every
  if[0=.state.counter mod .state.gravity .state.level;drop_piece[]];                            / x ms, as denoted by \t. the counter will go up by 1 every x ms, and the piece will drop
  .state.counter+:1;                                                                            / whenever the counter is equal to the gravity setting as denoted by the level. this is what
 };                                                                                             / essentially handles the difficulty scaling of the game as lines are cleared

start:{                                                                                         / the initial function which sets the game globals up once the start button is pressed
  .state.grid:enlist[12#enlist`],{(21#enlist x,(10#y),x),enlist raze 12#enlist x}. .state.colours`G`B; / make the grid of which the tetris game will be played on, including empty top line
  .state.v_offset:(div[.op.rows-22;2]+1 -1)#\:enlist"";
  .state.h_offset:div[.op.cols-22;2]#" ";
  .state[`game_started`game_end]:10b;                                                           / set the state to game started and not game ended
  .state[`piece`next_piece]:`$'2?"IOJLTZS";                                                     / choose the current and next piece(s)
  .state.piece:`I;
  .state[`orientation`next_orientation]:1 1?\:0 1 2 3;                                          / choose the current and next orientation(s) (weird way to enlist them both)
  .state.np_grid:next_piece_grid . .state`next_piece`next_orientation;                          / using the next piece and orientation, create a small grid for display purposes
  .state[`counter`score`lines`level]:4#0;                                                       / set all the scores/lines/levels to 0, and reset the counter for .z.ts purposes
  .state.centre:1 6;                                                                            / set the centre of the piece the top of the grid
  .state.active:{[po;pi;o;e]e+/:raze po[pi]o}. .state`pos`piece`orientation`centre;             / set the active indexes of the active piece

  system"t 10";                                                                                 / set the refresh rate of .z.ts to 10 ms, and this will automatically kick off .z.ts
 };

new_game[];                                                                                     / if the script is just ran, open up the menu
