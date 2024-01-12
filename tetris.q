/ IN GAME CONTROLS
/ [ENTER] = rotate clockwise
/ [SPACE] + [ENTER] = drop
/ [A] + [ENTER] = left
/ [D] + [ENTER] = right
/ [S] + [ENTER] = soft drop
/ [R] + [ENTER] = start/restart game
/ [X] + [ENTER] = return to menu

init:{                                                                                          / initialise some important operating system dependant and some state variables
  if[.op.win:.z.o like"w*";system"echo 1"];                                                     / check if the operating system is windows, and call a system command to avoid colour bugs
  .op.lin:.z.o like"l*";                                                                        / check if the operating system is linux
  if[all not .op`win`lin;-1"Unrecognised Operating System";exit 1];                             / if neither are true, then exit due to an untested operating system being used
  if[not`hiscore.csv in key`:.;`:hiscore.csv 0:csv 0:([]pos:1+til 16;score:n;lines:n;level:n:16#0N;name:16#`)]; / if the hi score csv doesnt exist, make one in the current directory
  .op.o:0 2 .op.win;                                                                            / offset special characters which have length 1 or 3 for windows and linux respectively
  .op.rows:$[.op.win;50;"J"$first system"tput lines"];                                          / use tput to get the window height, and just guess for windows since nothing similar exists
  .op.cols:$[.op.win;"J"$trim 12_system["mode con"]4;first"J"$system"tput cols"];               / use tput to get the window width, and use mode con if using windows
  .op.sleep:$[.op.lin;                                                                          / some effects utilise the operating systems sleep function
    {system"sleep ",string x};                                                                  /   for linux, easily use sleep
    {do[floor x*10;@[system;"ping 192.0.2.2 -n 1 -w 0.1 > nul";{x;}]]}                          /   for windows, use ping on a non existent address to sleep quickly, then repeat x times
  ];                                                                                            /   cant use TIMEOUT since it only accepts seconds, this is the easiest method ive found...
  .op.char.all:(1 3)[.op.lin]cut first read0`:art/char.txt;                                     / assign all special characters to its own global variables
  .op.char[`b`pipe_vleft`pipe_vert`corner_bl`corner_tl`corner_tr`corner_br`pipe_vright`pipe_flat]:.op.char.all; / assign the standard block and pipe characters to their own dictionaru

  system"S ",-5#string .z.p;                                                                    / get a random seed based on current time
  system"c ",string[2+.op.rows]," 500";                                                         / set the console size based on the current window size

  .state.pos:(!/)flip 2 cut                                                                     / make a dictionary for all shapes centered on an index of (0;0), this also contains each
   (`I  ;4#((-1 0;0 0;1 0;2 0);(-1 -1;-1 0;-1 1;-1 2));                                         / rotation of the each shape going clockwise in order
    `O  ;4#enlist(-1 -1;-1 0;0 -1;0 0);                                                         / eg .state.pos[L;0] rotates clockwise is .state.pos[L;1] and so on...
    `J  ;((0 -1;0 0;0 1;1 1);(-1 0;0 0;1 0;1 -1);(-1 -1;0 -1;0 0;0 1);(-1 1;-1 0;0 0;1 0));
    `L  ;((0 -1;0 0;0 1;1 -1);(-1 -1;-1 0;0 0;1 0);(-1 1;0 -1;0 0;0 1);(-1 0;0 0;1 0;1 1));
    `T  ;((0 -1;0 0;0 1;1 0);(-1 0;0 -1;0 0;1 0);(-1 0;0 -1;0 0;0 1);(-1 0;0 0;0 1;1 0));
    `S  ;4#((0 0;0 1;1 -1;1 0);(-1 -1;0 -1;0 0;1 0));
    `Z  ;4#((0 -1;0 0;1 0;1 1);(-1 0;0 -1;0 0;1 -1)));

  .state.colours:(!/)flip 2 cut                                                                 / make a dictionary of all shapes to colours, i think more colours can be used using a
   (`I  ;`$"\033[36m",.op.char.b,"\033[0m";  `O  ;`$"\033[33m",.op.char.b,"\033[0m";            / more complicates ascii code, but if it isnt broken, dont fix it
    `J  ;`$"\033[34m",.op.char.b,"\033[0m";  `L  ;`$"\033[29m",.op.char.b,"\033[0m";
    `T  ;`$"\033[35m",.op.char.b,"\033[0m";  `S  ;`$"\033[32m",.op.char.b,"\033[0m";
    `Z  ;`$"\033[31m",.op.char.b,"\033[0m";  `B  ;`$"\033[30m",.op.char.b,"\033[0m";
    `G  ;`$"\033[37m",.op.char.b,"\033[0m");

  .state.gravity:`s#(til[11],13 16 19 29)!48 43 38 33 28 23 18 13 8 6 5 4 3 2 1;                / make a step dictionary for the falling speeds (gravity) for each level(s)
  .state.menu.main:1b;                                                                          / set the location to the main menu (and initailise the global variable)
  .state.menu[`in_game`hiscores`game_end]:000b;                                                 / set the locations of all other menus that we are not in

  .state.cursor:0;                                                                              / initialise where the cursor is
  .state.menu.main_start:{.state.menu[`main`in_game`game_end]:010b;start[]};                    / set the in game location and start the game
  .state.menu.main_exit:{exit 0};                                                               / exit the game if the exit option was selected
  .state.menu.main_hi_score:{.state.menu[`main`hiscores`rhs]:010b;.state.cursor:0;hi_scores[]}; / set the hi scores location, reset the cursor, and go to the hi scores

  .state.menu.hiscores_return:{.state.menu[`hiscores`main]:01b;.state.cursor:0;main_menu[]};    / set the main menu location, reset the cursor, and go to the main menu
  .state.menu.hiscores_reset:{reset_hi_scores[]};                                               / if the reset hi score option was selected, either confirm or delete the hi scores

  .state.menu.game_end_retry:{.state.menu[`game_end`in_game]:01b;start[]};                      / set the in game location and restart the game
  .state.menu.game_end_return:{.state.menu[`game_end`main]:01b;.state.cursor:0;main_menu[]};    / set the main menu location, reset the cursor, and go to the main menu

  main_menu[];                                                                                  / start up the game
 };

print_screen:{                                                                                  / function for printing the screen based on the current grid
  r:(raze/')string 2#''x;                                                                       / since a block █ is quite thin, expand it to make a square ██
  r:@[r;1;,;{" ",x,raze[10#enlist y],z}. .op.char`corner_br`pipe_flat`corner_bl];               / create the top border for the score panel
  r:@[r;4 7 10;,;3#enlist{" ",x,raze[10#enlist y],z}..op.char`pipe_vright`pipe_flat`pipe_vleft]; / create the middle border things for the score panel
  r:@[r;16;,;{" ",x,raze[10#enlist y],z}. .op.char`corner_tr`pipe_flat`corner_tl];              / create the bottom border for the score panel
  r:@[r;2 3;,;(" ",c),/:(-9$("SCORE";string .state.score)),\:" ",c:.op.char.pipe_vert];         / append the current score on the 2nd and 3rd row
  r:@[r;5 6;,;(" ",c),/:(-9$("LEVEL";string .state.level)),\:" ",c];                            / append the current level on on the 5th and 6th row
  r:@[r;8 9;,;(" ",c),/:(-9$("LINES";string .state.lines)),\:" ",c];                            / append the current lines cleared on the 8th and 9th row
  r:@[r;11 12 13 14 15;,;(" ",c),/:((raze/')string 2#''.state.np_grid),\:c];                    / below the lines, display the next piece, this piece has there own little grid
  if[.state.menu.game_end;r:$[.state.new_hi_score;gen_new_hiscore_screen r;gen_end_screen r]];  / if the game end is triggered, overlay the game end message
  -1{z[0],(y,/:x),z 1}[r]..state`h_offset`v_offset;                                             / add the horizontal and vertical offsets to make the grid central
 };

gen_end_screen:{                                                                                / if the game has ended, add the overlay to the current grid
  f:{[o;i;m;x]raze@[(12-o)cut x;i;:;m]}.op.o;                                                   / define the function to help, this is awkward since the blocks have 10/12 characters
  r:@[x;5 19;f[i;string .state.colours count[i:4+til 16]#`G]];                                  / make top and bottom borders
  r:@[r;6+til 13;f[i;string .state.colours`$'"GG",(12#"B"),"GG"]];                              / make left and right borders
  r:@[r;7;f[7 8 9 10 12 13 14 15;"GAMEOVER"]];                                                  / assign GAME OVER at the top of the box
  r:@[r;9;f[7 8 9 10 11 12;"PLEASE"]];                                                          / assign PLEASE below
  r:@[r;10;f[8 9 10;"TRY"]];                                                                    / assign TRY below that
  r:@[r;11;f[9 10 11 12 13 15;("A";"G";"A";"I";"N";("\342\231\245";"\003").op.win)]];           / assign AGAIN ♥ below that, again awkward because the heart has 3/1 characters
  r:@[r;13;f[9 10 11 12 13;"RETRY"]];                                                           / assign the RETRY menu option
  r:@[r;16;f[9 10 11 12;"MENU"]];                                                               / assign the MENU option
  cursor:(1 3)[.op.lin]cut raze .op.char`corner_tr,((5 4)[.state.cursor]#`pipe_flat),`corner_tl;
  :(@[r;14;f[8+til count cursor;cursor]];@[r;17;f[8+til count cursor;cursor]]).state.cursor;
 };

gen_new_hiscore_screen:{                                                                        / if a new hi score is acheived, we want this to flash up before the end game screen
  f:{[o;i;m;x]raze@[(12-o)cut x;i;:;m]}.op.o;                                                   / define the function to help, this is awkward since the blocks have 10/12 characters
  r:@[x;8 15;f[i;string .state.colours count[i:3+til 18]#`G]];                                  / make top and bottom borders
  r:@[r;9+til 6;f[i;string .state.colours`$'"GG",(14#"B"),"GG"]];                               / make left and right borders
  r:@[r;10;f[6 7 8 10 11 13 14 15 16 17;"NEWHISCORE"]];
  r:@[r;12;f[6 7 8 9 10 12 13 14 15;"Enteryour"]];
  :@[r;13;f[6 7 8 9 11 12 13 14 15 16;"namebelow:"]];
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
    :();                                                                                        /   finally leave early, so that the drop_piece function can run again before outputting
  ];
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;                             / all the spaces below were black, and the piece just drops a row, assign it to the grid
  print_screen .state.grid;                                                                     / output the current state to console
 };

row_complete:{                                                                                  / this runs if 1 or more rows are full, we need to get rid of them and add up scores
  .state.menu.in_game:0b;                                                                       / pretend we are not in a game to disable .z.pi inputs
  c:@[.state.grid;w;:;e:count[w:1+where x]#enlist {x,(10#y),x}..state.colours`G`B];             / make a copy of the grid where the completed rows are replaced with blank rows
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
  .state.menu.in_game:1b;                                                                       / re-enable all key inputs
 };

game_over:{                                                                                     / if the game is over, we want to stop everything and finalise the grid
  .state.menu[`in_game`game_end]:01b;                                                           / set the state to game end, so that the appropriate game end screen is displayed
  .[`.state.grid;;:;.state.colours .state.piece]each 1 0+/:.state.active;                       / drop the current piece anyway and set it to the grid (like the nes version)
  hs:("JJJJS";enlist",")0:`:hiscore.csv;                                                        / pull up the hi scores
  if[.state.new_hi_score:(.state.score>=min hs`score)|0N in hs`score;                           / is our score equal to or higher then the lowest hi score, or are there empty spots?
    hs:`score`lines`level xdesc hs upsert 0,.state[`score`lines`level],`;                       /   add the new score to the hi scores table, and order them by score, then lines, then level
    .state.hiscore_rank:1+first where 0=hs`pos;                                                 /   what is the rank of the new hi score, need this so we know where to assign the name
    if[17=.state.hiscore_rank;.state.new_hi_score:0b];                                          /   in the extremely unlikely event of a tie at pos 16, dont bother updating the hi score
    .state.hiscores:16#@[hs;`pos;:;1+til 17];                                                   /   relabel the position column and remove the overflow
  ];                                                                                            /   note - any ties are pushed down a rank eg tieing for pos 5 will be push you to pos 6
  print_screen .state.grid;                                                                     / print the screen with the game end message to the console
  system"t 0";                                                                                  / pause .z.ts so nothing else happens
 };                                                                                             / we dont need to disable inputs here since all game end user inputs will be evaluated

commit_hi_score:{
  .state.new_hi_score:0b;                                                                       / disable the new hi score state so we dont repeat this action
  if[not count -1_trim x;x:(3?.Q.a),"\n"];                                                      / if the user entered nothing, then generate 3 random letters in true arcade style
  .state.hiscores:update name:`$10$-1_x from .state.hiscores where pos=.state.hiscore_rank;     / update the name of the new hi score
  `:hiscore.csv 0:csv 0:.state.hiscores;                                                        / overwrite the old hi scores with the new record added
 };

main_menu:{                                                                                     / function to create a fancy title screen
  col_map:(5#'string .state.colours)[`$'"ZLOSIT"],enlist"\033[0m";                              / get the strings for each corresponding colours
  logo:ssr/[;"ZLOSITN";col_map]each read0`:art/logo.txt;                                        / convert the text strings to their colours blocks and join them
  opts:(4#" "),(18#" ")sv("START";"HI SCORES";"QUIT");                                          / add an empty line followed by the menu options
  i:{x[0],1+last[x]-x 0}each where[not deltas[a]in 1 2]cut a:where opts<>" ";                   / weird way to find where the menu options are and get the first index and how many chars
  cursor:@[;.state.cursor]{#[x-1;" "],raze .op.char`corner_tr,(y#`pipe_flat),`corner_tl}.'i;    / generate the cursor line, and position it under the current option
  copy:((16#" "),"Version 1.0.0    "),("\302\251";"\270")[0]," 1989 Nintendo";                  / add a couple of empty lines followed by the copyright info, getting right code from os
  v_pad:div[-10+.op.rows;2];                                                                    / allocate padding to put above and below the logo, so as it is central
  h_pad:floor[(.op.cols-64)%2]#" ";                                                             / allocate padding to put in front of the logo to make it in the middle of the screen
  -1 ((v_pad+5)#enlist""),(h_pad,/:logo,("";"";opts;cursor;"";"";copy)),(v_pad-5)#enlist"";     / join them all together and output it to the console
 };

hi_scores:{                                                                                     / function to create a fancy hi scores screen
  hs:ssr/[;"ZN";("\033[31m";"\033[0m")]each read0`:art/hi_scores.txt;                           / convert the text strings to their colours blocks and join them
  scores:@[flip","vs'1_read0`:hiscore.csv;0;{-12$"\033[31m",x,".\033[0m"}'];                    / read the scores as strings, and format the pos numbers to be red
  scores:" "sv'flip@[scores;1 2 3 4;{" ",-10$" ",x}'];                                          / for each score and name, pad out thr string so it is at most 10 characters long
  head:"    "," "sv -11$("score";"lines";"level";"name");                                       / make the headers for each column
  main:hs,("";"";p,head),(p:10#" "),/:scores;                                                   / join them all together with some padding and blank lines
  opts:(15#" "),(20#" ")sv("RETURN TO MENU";("RESET HI SCORES";" ARE YOU SURE?").state.menu.rhs); / join up the menu options, and check if we are in the normal or resetting state
  i:{x[0],1+last[x]-x 0}each where[n:not deltas[a]in 1 2]cut a:where opts<>" ";                 / weird way to find where the menu options are and get the first index and how many chars
  cursor:@[;.state.cursor]{#[x-1;" "],raze .op.char`corner_tr,(y#`pipe_flat),`corner_tl}.'i;    / generate the cursor line, and position it under the current option
  h_pad:floor[(.op.cols-78)%2]#" ";                                                             / allocate padding to put above and below the screen, so as it is central
  v_pad:div[.op.rows-24;2]#enlist"";                                                            / allocate padding to put in front of the screen to make it in the middle of the screen
  -1 v_pad,(h_pad,/:main,("";opts;cursor)),2_v_pad;                                             / join them all together and output it to the console
 };

reset_hi_scores:{
  if[.state.menu.rhs;`:hiscore.csv 0:csv 0:([]pos:1+til 16;score:n;lines:n;level:n:16#0N;name:16#`)]; / if the user has confirmed deletion, overwrite the hi scores with an empty table
  .state.menu.rhs:not .state.menu.rhs;                                                          / flip the state to on if we are confirming the deletion, or off if deletion happened
  hi_scores[];                                                                                  / in either case reprint the hi scores with the confirmation message/cleared hi scores
 };

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

.z.pi:{                                                                                         / user input handler, only 1 check should pass, but leave early everytime anyway
  if[.state.menu.main;                                                                          / if we are on the menu screen
    $[x like"[aA]*";[.state.cursor:0|2&.state.cursor-1;main_menu[]];                            /   move the cursor to the left
      x like"[dD]*";[.state.cursor:0|2&.state.cursor+1;main_menu[]];                            /   move the cursor to the right
      x~enlist"\n";.state.menu[`main_start`main_hi_score`main_exit][.state.cursor][];           /   execute the option indicated by the cursor
      ::];                                                                                      /   and nothing else
    :()];                                                                                       /   finally leave early to avoid other checks running
  if[.state.menu.in_game;                                                                       / if we are in the game
    $[x like"[aA]*";move -1;                                                                    /   if the user pressed a, then move the active pieve to the left
      x like"[dD]*";move 1;                                                                     /   if the user pressed d, then move the active piece to the right
      x like"[sS]*";drop_piece[];                                                               /   if the user pressed s, we want to softly drop the active piece one line
      x like"[xX]*";[.state.menu[`main`in_game]:10b;system"t 0";main_menu[]];                   /   if the user pressed x, stop .z.ts, go back to the main menu
      x like"[rR]*";start[];                                                                    /   if the user pressed n, restart the game
      x like" *";slam[];                                                                        /   if the user pressed the space bar, hard drop the active pieve
      x~enlist"\n";rotate_piece[];                                                              /   if just enter was hit, rotate the active piece clockwise
      ::];                                                                                      /   and nothing else
    :()];                                                                                       /   finally leave early to avoid any other checks running
  if[.state.menu.hiscores;                                                                      / if we are on the hi score menu
    $[x like"[aA]*";[.state.cursor:0|1&.state.cursor-1;hi_scores[]];                            /   move the cursor to the left
      x like"[dD]*";[.state.cursor:0|1&.state.cursor+1;hi_scores[]];                            /   move the cursor to the right
      x~enlist"\n";.state.menu[`hiscores_return`hiscores_reset][.state.cursor][];               /   execute the option indicated by the cursor
      ::];                                                                                      /   and nothing else
    :()];                                                                                       /   finally leave early to avoid any other checks running
  if[.state.menu.game_end;                                                                      / if we are on the game end screen
    if[.state.new_hi_score;commit_hi_score x;print_screen .state.grid;:()];                     /   if there is a new hi score, use the user input to assign a name to the new high score
    $[x like"[wW]*";[.state.cursor:0|1&.state.cursor-1;print_screen .state.grid];               /   move the cursor to up
      x like"[sS]*";[.state.cursor:0|1&.state.cursor+1;print_screen .state.grid];               /   move the cursor to down
      x~enlist"\n";.state.menu[`game_end_retry`game_end_return][.state.cursor][];               /   execute the option indicated by the cursor
      ::];                                                                                      /   and nothing else
    :()];                                                                                       /   finally return early (i know this is the last function, but keep this for continuity)
 };

.z.ts:{                                                                                         / the timer of which the game functions and updates, this function will be executed every
  if[0=.state.counter mod .state.gravity .state.level;drop_piece[]];                            / x ms, as denoted by \t. the counter will go up by 1 every x ms, and the piece will drop
  .state.counter+:1;                                                                            / whenever the counter is equal to the gravity setting as denoted by the level. this is what
 };                                                                                             / essentially handles the difficulty scaling of the game as lines are cleared

start:{                                                                                         / the initial function which sets the game globals up once the start button is pressed
  .state.grid:enlist[12#enlist`],{(21#enlist x,(10#y),x),enlist raze 12#enlist x}. .state.colours`G`B; / make the grid of which the tetris game will be played on, including empty top line
  .state.v_offset:(div[.op.rows-22;2]+1 -1)#\:enlist"";                                         / set how much padding is required to bring the grid UP to the centre of the screen
  .state.h_offset:div[.op.cols-22;2]#" ";                                                       / set how much padding is required to bring the grid from the LEFT to the centre
  .state[`piece`next_piece]:`$'2?"IOJLTZS";                                                     / choose the current and next piece(s)
  .state[`orientation`next_orientation]:1 1?\:0 1 2 3;                                          / choose the current and next orientation(s) (weird way to enlist them both)
  .state.np_grid:next_piece_grid . .state`next_piece`next_orientation;                          / using the next piece and orientation, create a small grid for display purposes
  .state[`counter`score`lines`level]:4#0;                                                       / set all the scores/lines/levels to 0, and reset the counter for .z.ts purposes
  .state.centre:1 6;                                                                            / set the centre of the piece the top of the grid
  .state.active:{[po;pi;o;e]e+/:raze po[pi]o}. .state`pos`piece`orientation`centre;             / set the active indexes of the active piece

  system"t 10";                                                                                 / set the refresh rate of .z.ts to 10 ms, and this will automatically kick off .z.ts
 };

init[];
