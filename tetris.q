/ [ENTER] = rotate clockwise
/ [SPACE] + [ENTER] = drop
/ [A] + [ENTER] = left
/ [D] + [ENTER] = right

.state.pos:(!/)flip 2 cut
 (`I  ;4#((-1 0;0 0;1 0;2 0);(-1 -1;-1 0;-1 1;-1 2));
  `O  ;4#enlist(-1 0;-1 1;0 0;0 1);
  `J  ;((0 -1;0 0;0 1;1 1);(-1 0;0 0;1 0;1 -1);(-1 -1;0 -1;0 0;0 1);(-1 1;-1 0;0 0;1 0));
  `L  ;((0 -1;0 0;0 1;1 -1);(-1 -1;-1 0;0 0;1 0);(-1 1;0 -1;0 0;0 1);(-1 0;0 0;1 0;1 1));
  `T  ;((0 -1;0 0;0 1;1 0);(-1 0;0 -1;0 0;1 0);(-1 0;0 -1;0 0;0 1);(-1 0;0 0;0 1;1 0));
  `S  ;4#((0 0;0 1;1 -1;1 0);(-1 -1;0 -1;0 0;1 0));
  `Z  ;4#((0 -1;0 0;1 0;1 1);(-1 0;0 -1;0 0;1 -1)));

.state.colours:(!/)flip 2 cut
 (`I  ;`$"\033[36m\342\226\210\033[0m";
  `O  ;`$"\033[33m\342\226\210\033[0m";
  `J  ;`$"\033[34m\342\226\210\033[0m";
  `L  ;`$"\033[29m\342\226\210\033[0m";
  `T  ;`$"\033[35m\342\226\210\033[0m";
  `S  ;`$"\033[32m\342\226\210\033[0m";
  `Z  ;`$"\033[31m\342\226\210\033[0m";
  `B  ;`$"\033[30m\342\226\210\033[0m";
  `G  ;`$"\033[37m\342\226\210\033[0m");

.state.gravity:`s#(til[11],13 16 19 29)!48 43 38 33 28 23 18 13 8 6 5 4 3 2 1;

print_screen:{
  r:(raze/')string 2#''x;
  o:.state.offset;
  r:@[r;o+2 3;,;-9$("SCORE";string .state.score)];
  r:@[r;o+5 6;,;-9$("LEVEL";string .state.level)];
  r:@[r;o+8 9;,;-9$("LINES";string .state.lines)];
  r:@[r;o+11 12 13 14 15;,;(raze/')string 2#''.state.np_grid];
  if[.state.game_end;r:gen_end_screen r];
  -1 r;
 };

gen_end_screen:{
  o:.state.offset;
  r:@[x;o+4 18;{raze@[12 cut x;i;:;string .state.colours count[i:4+til 16]#`G]}];
  r:@[r;o+5+til 13;{raze@[12 cut x;4+til 16;:;string .state.colours`$'"GG",(12#"B"),"GG"]}];
  r:@[r;o+6;{raze@[12 cut x;7 8 9 10 12 13 14 15;:;"GAMEOVER"]}];
  r:@[r;o+8;{raze@[12 cut x;7 8 9 10 11 12;:;"PLEASE"]}];
  r:@[r;o+9;{raze@[12 cut x;8 9 10;:;"TRY"]}];
  r:@[r;o+10;{raze@[12 cut x;9 10 11 12 13 15;:;("A";"G";"A";"I";"N";"\342\231\245")]}];
  r:@[r;o+12;{raze@[12 cut x;7 8 9 10 11 13;:;"PressN"]}];
  r:@[r;o+13;{raze@[12 cut x;8 9 11 12 13 14 15;:;"toretry"]}];
  r:@[r;o+15;{raze@[12 cut x;7 8 9 10 11 13;:;"PressX"]}];
  :@[r;o+16;{raze@[12 cut x;8 9 11 12 13 14;:;"toexit"]}];
 };

new_piece:{
  .state.piece:.state.next_piece;
  .state.orientation:.state.next_orientation;
  .state.next_piece:`$1?"IOJLTZS";
  .state.next_orientation:1?0 1 2 3;
  .state.np_grid:next_piece_grid . .state`next_piece`next_orientation;
  .state.centre:.state.offset,6;
  .state.active:{[po;pi;o;e]e+/:raze po[pi]o}. .state`pos`piece`orientation`centre;
  drop_piece[];
 };

next_piece_grid:{[np;no]
  .state.np_grid:5#enlist 5#.state.colours`B;
  n:2 2+/:raze .state.pos[np]no;
  .[`.state.np_grid;;:;.state.colours np]each n;
  .state.np_grid
 };

drop_piece:{
  .[`.state.grid;;:;.state.colours`B]each .state.active;
  .state.active:.state.active+\:1 0;
  .state.centre:.state.centre+1 0;
  if[any .state.colours[`B]<>.state.grid ./:.state.active;
    .state.active:.state.active+\:-1 0;
    if[.state.offset in .state.active[;0];game_over[];:()];
    .[`.state.grid;;:;.state.colours .state.piece]each .state.active;
    if[any r:all each .state.colours[`B]<>-1_.state.grid;row_complete r];
    new_piece[];
    :();
  ];
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;
  print_screen .state.grid;
 };

row_complete:{
  c:@[.state.grid;w;:;e:count[w:where x]#enlist {x,(10#y),x}. .state.colours`G`B];
  system"sleep 0.2"
  print_screen c;
  do[3; / a little bit naughty
    system"sleep 0.2"
    print_screen .state.grid;
    system"sleep 0.2"
    print_screen c;
  ];
  .state.grid:c;
  {.state.grid:.state.grid _ x}each desc where x;
  pad:(.state.offset#enlist 12#enlist .state.colours`B);
  .state.grid:pad,e,.state.offset _ .state.grid;
  .state.lines+:sum x;
  .state.score+:(1 2 3 4i!40 100 300 1200*.state.level+1)sum x;
  .state.level:.state.lines div 10;
 };

game_over:{
  .state.game_end:1b;
  .state.active:1 0+/:.state.active;
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;
  print_screen .state.grid;
  .state.game_started:0b;
  system"t 0";
 };

new_game:{
  .state.game_started:0b;
  l1:"BTTTTTBOOOOOBJJJJJBZZZZBBIIIBBSSSSB";
  l2:"BBBTBBBOBBBBBBBJBBBZBBBZBBIBBSBBBBB";
  l3:"BBBTBBBOOOOBBBBJBBBZZZZBBBIBBBSSSBB";
  l4:"BBBTBBBOBBBBBBBJBBBZBBZBBBIBBBBBBSB";
  l5:"BBBTBBBOOOOOBBBJBBBZBBBZBIIIBSSSSBB";
  logo:(raze/')string 2#''.state.colours`$''(l1;l2;l3;l4;l5);
  i:("";"";"   Press N to start a new game                    Press X to exit");
  c:("";"";"                            \302\251 1989 Nintendo");
  p:div[;2] -10+m:"J"$first system"tput lines";
  system"c ",string[2+m]," 500";
  -1 ((p+5)#enlist""),logo,i,c,(p-5)#enlist"";
 };

move:{
  .[`.state.grid;;:;.state.colours`B]each .state.active;
  e:.state.active where{y=x y}[(min;max)1=x;.state.active[;1]];
  if[all .state.colours[`B]=.state.grid ./:e+\:0,x;
    .state.active:.state.active+\:0,x;
    .state.centre:.state.centre+0,x;
  ];
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;
  print_screen .state.grid;
 };

slam:{
  .[`.state.grid;;:;.state.colours`B]each .state.active;
  b:.state.grid ./:/:.state.active+/:\:til[23],'0;
  .state.active:.state.active+\:min[-1+min each where each .state.colours[`B]<>b],0;
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;
  print_screen .state.grid;
  if[any r:all each .state.colours[`B]<>-1_.state.grid;row_complete r];
  new_piece[];
 };

rotate_piece:{
  .[`.state.grid;;:;.state.colours`B]each .state.active;
  .state.orientation:mod[;4].state.orientation+1;
  n:{[po;pi;o;e]e+/:raze po[pi]o}. .state`pos`piece`orientation`centre;
  if[any .state.colours[`B]<>.state.grid ./:n;:()]; / TODO - implement wall kick
  .state.active:n;
  .[`.state.grid;;:;.state.colours .state.piece]each .state.active;
  print_screen .state.grid;
 };

.z.pi:{
  if[not .state.game_started;$[x like"[nN]*";start[];x like"[xX]*";exit 0;:()]];
  $[
    x like"[aA]*";move -1;
    x like"[dD]*";move 1;
    x like"[sS]*";drop_piece[];
    x like"[xX]*";exit 0;
    x like"[nN]*";start[];
    x like" *";slam[];
    rotate_piece[]
  ];
 };

.z.ts:{
  if[0=.state.counter mod .state.gravity .state.level;drop_piece[]];
  .state.counter+:1;
 };

start:{
  system"S ",-5#string .z.p;

  gb:.state.colours`G;
  bb:.state.colours`B;
  .state.grid:(21#enlist gb,(10#bb),gb),enlist raze 12#enlist gb;
  .state.offset:(m:"J"$first system"tput lines")-count .state.grid;
  .state.grid:(.state.offset#enlist 12#enlist bb),.state.grid;
  .state.game_started:1b;
  .state.game_end:0b;
  .state.counter:0;
  .state.piece:`$1?"IOJLTZS";
  .state.next_piece:`$1?"IOJLTZS";
  .state.orientation:1?0 1 2 3;
  .state.next_orientation:1?0 1 2 3;
  .state.np_grid:next_piece_grid . .state`next_piece`next_orientation;
  .state.score:0;
  .state.lines:0;
  .state.level:0;
  .state.centre:.state.offset,6;
  .state.active:{[po;pi;o;e]e+/:raze po[pi]o}. .state`pos`piece`orientation`centre;

  system"t 10";
 };

new_game[];
