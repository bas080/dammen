module(dammen, [options/3, options/1, option/3, perform/2, field/1]).

field(X) :-
  between(1, 50, X).

row_direction_offset(Offset, A) :-
  mod(A - 1, 10) < 5
  -> Offset = 1
  ;  Offset = 0,
  !.

direction(north, ne).
direction(north, nw).
direction(south, se).
direction(south, sw).

direction(ne).
direction(nw).
direction(se).
direction(sw).

borders(A, top) :-
  A < 6.

borders(A, bottom) :-
  A > 45.

movement(sw, 4).
movement(ne, -5).
movement(se, 5).
movement(nw, -6).

neighbors(A, B) :-
  neighbors(A, B, _).

neighbors(A, B, D) :-
  field(B),
  movement(D, I),
  row_direction_offset(Offset, B),
  A is (B + Offset + I),
  \+ row_direction_offset(Offset, A).

% Pieces

man(white).
man(black).

king(white).
king(black).

piece(man).
piece(king).
piece(Piece, Color, Field) :-
  color(Color),
  piece(Piece),
  field(Field).

% Board

board_piece(piece(man, white, X)) :-
  field(X),
  X > 30.

board_piece(piece(man, black, X)) :-
  field(X),
  X < 21.

board(Board) :-
  findall(Piece, board_piece(Piece), Board).

random_board(Board) :-
  between(2, 40, N),
  length(S, 40),
  Piece = piece(_, _, _),
  member(Piece, S),
  permutation(S, Board).

% Turns

shares_line_with(A, B) :-
  shares_line_with(A, B, _).

shares_line_with(A, B, D) :-
  neighbors(A, B, D).

shares_line_with(A, B, D) :-
  neighbors(A, C, D),
  shares_line_with(C, B, D).

% Moving and capturing movement.

color(white, black).
color(black, white).
color(white).
color(black).

between_fields(From, To, Captured) :-
  From >= To,
  between_fields(To, From, Captured).

between_fields(From, To, Captured) :-
  From =\= To,
  From < Captured,
  To > Captured,
  !.

moves_towards_the(black, south).
moves_towards_the(white, north).

% When moving a man to the oppisite of the board it becomes a king.

king_side(black, bottom).
king_side(white, top).
becomes(A, B) :-
  (
    A = piece(man, Color, Field),
    king_side(Color, Border),
    borders(Field, Border)
  ) -> B = piece(king, Color, Field) ; B = A.

% Moving (board)

move(piece(man, Color, From), ToPiece) :-
  moves_towards_the(Color, ColorDirection),
  direction(ColorDirection, Direction),
  neighbors(To, From, Direction),
  becomes(piece(man, Color, To), ToPiece).

move(piece(king, Color, From), piece(king, Color, To)) :-
  shares_line_with(From, To).

% consider refacroring the move into a king and man move
move(FromPiece, ToPiece, Board) :-
  member(FromPiece, Board),
  move(FromPiece, ToPiece),
  ToPiece = piece(_, _, To),
  FromPiece = piece(_, _, From),
  \+ pieces_between(From, To, _, Board), % is only required when piece is a king
  \+ member(piece(_, _, To), Board).

move(FromPiece, ToPiece, BoardIn, BoardOut) :-
  move(FromPiece, ToPiece, BoardIn),
  replace(FromPiece, ToPiece, BoardIn, BoardOut).

pieces_between(From, To, Piece, Board) :-
  shares_line_with(From, Middle, D),
  shares_line_with(Middle, To, D),
  between_fields(From, To, Middle),
  member(Piece, Board),
  Piece = piece(_, _, Middle).

% Capturing (board)

% Consider refactoring the top three capture into two fn one for man and one
% for king

capture(Captures, capture(Captures)) :- !.

capture(piece(man, Color, From),
        piece(man, Color, To),
        piece(_, Opposite, CaptureField)) :-
  neighbors(CaptureField, From, D),
  neighbors(To, CaptureField, D),
  color(Color, Opposite).

capture(piece(king, Color, From),
        piece(king, Color, To),
        piece(_, Opposite, CaptureField)) :-
  shares_line_with(From, CaptureField, D),
  shares_line_with(CaptureField, To, D),
  color(Color, Opposite).

capture(FromPiece, ToPiece, Captured, Board) :-
  member(FromPiece, Board),
  member(Captured, Board),
  capture(FromPiece, ToPiece, Captured),
  ToPiece = piece(_, _, To),
  FromPiece = piece(_, _, From),
  \+ member(piece(_, _, To), Board),
  once(findnsols(2, P, pieces_between(From, To, P, Board), Pieces)),
  length(Pieces, 1).

capture(From, To, Captured, Board, BoardOut) :-
  capture(From, To, Captured, Board),
  exclude(=(Captured), Board, B1),
  replace(From, To, B1, BoardOut).

% Last move in a capture
captures([From, To], Board, BoardOut) :-
  capture(From, A, _, Board, B1),
  becomes(A, To),
  replace(A, To, B1, BoardOut).

captures([From, To, Next|Rest], Board, BoardOut) :-
  capture(From, To, _, Board, BoardNext),
  From = piece(_, _, A),
  To = piece(_, _, B),
  Next = piece(_, _,C),
  shares_line_with(A, B, D),
  shares_line_with(C, B, DD),
  D \= DD,
  captures([To, Next|Rest], BoardNext, BoardOut).

captures(Captures, Board) :-
  captures(Captures, Board, _).

length_equals(V, L) :-
  length(L, LL),
  LL =\= V.

longest(Lists, ListsOut) :-
  maplist(length, Lists, X),
  max_list(X, Y),
  exclude(length_equals(Y), Lists, ListsOut).

options(Board, Options) :-
  options(Board, white, Options).

% Maybe also respond with board layout.
% TODO: check if there is longest king move otherwise all.
options(Board, Color, Options) :-
  findall(
    Moves,
    (
      captures(Moves, Board),
      Moves = [piece(_, Color, _)|_]
    ),
    Captures
  ),
  Captures = [_|_],
  longest(Captures, A),
  maplist(capture, A, Options),
  !.

options(Board, Color, Options) :-
  findall(move(From, To), (
     move(From, To, Board),
    From = piece(_, Color, _)
  ), Options), !.

perform(A, BoardOut) :-
  board(Board),
  perform(A, Board, BoardOut).

perform(capture(Moves), Board, BoardOut) :-
  captures(Moves, Board, BoardOut).

perform(move(From, To), Board, BoardOut) :-
  move(From, To, Board, BoardOut).

perform([], A, A) :- !.

perform([Turn|Rest], Board, BoardOut) :-
  Turn = turn(_, _, Color),
  options(Board, Color, Options),
  option(Options, Turn, Option),
  perform(Option, Board, BoardNext),
  cli:pp_board(BoardNext),
  perform(Rest, BoardNext, BoardOut).

option(Options, turn(From, To, Color), Option) :-
  member(Option, Options),
  Option = move(piece(_, Color, From), piece(_, Color, To)),
  !.

option(Options, turn(From, To, _), Option) :-
  member(Option, Options),
  Option = capture([piece(_, _, From)|Rest]),
  last(Rest, piece(_, _, To)),
  !.

% HELPERS

replace(A, A, B, B) :- !.
replace(_, _, [], []).
replace(O, R, [O|T], [R|T2]) :- replace(O, R, T, T2).
replace(O, R, [H|T], [H|T2]) :- H \= O, replace(O, R, T, T2).
