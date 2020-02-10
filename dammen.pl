module(dammen, [options/3, options/1, option/3, perform/2]).

field(X) :-
  between(1, 50, X).

row_of(I, A) :-
  I is ceiling(A / 5).

row_parity_of(odd, A) :-
  row_of(I, A),
  mod(I, 2) =:= 1,
  !.

row_parity_of(even, A) :-
  \+ row_parity_of(odd, A).

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

borders(A, right) :-
  mod(A, 10) =:= 5.

borders(A, left) :-
  mod(A, 10) =:= 6.

neighbor_to(sw, A) :-
  \+ borders(A, bottom),
  \+ borders(A, left).

neighbor_to(se, A) :-
  \+ borders(A, bottom),
  \+ borders(A, right).

neighbor_to(nw, A) :-
  \+ borders(A, top),
  \+ borders(A, left).

neighbor_to(ne, A) :-
  \+ borders(A, top),
  \+ borders(A, right).

movement(sw, odd, 5).
movement(sw, even, 4).
movement(ne, odd, -4).
movement(ne, even, -5).
movement(se, odd, 6).
movement(se, even, 5).
movement(nw, odd, -5).
movement(nw, even, -6).

neighbors(A, B) :-
  neighbors(A, B, _).

neighbors(A, B, D) :-
  field(A),
  field(B),
  neighbor_to(D, B),
  row_parity_of(T, B),
  movement(D, T, I),
  A is B + I.

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

test_board(Board) :-
  Board = [
    piece(man, black, 22),
    %piece(man, black, 28),
    piece(man, black, 32),
    piece(man, black, 33),
    piece(man, white, 29),
    piece(man, black, 39)].

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
  From =\= To,
  From >= To,
  between_fields(To, From, Captured).

between_fields(From, To, Captured) :-
  From < Captured,
  To > Captured.

moves_towards_the(black, south).
moves_towards_the(white, north).

% When moving a man to the oppisite of the board it becomes a king.

becomes_king_when_reaching(black, bottom).
becomes_king_when_reaching(white, top).
becomes(piece(man, Color, Field), piece(king, Color, Field)) :-
  field(Field),
  becomes_king_when_reaching(Color, Border),
  borders(Field, Border).

becomes(A, A) :- % Stays the same when it doesn't become a king.
  \+ becomes(A, piece(king, _, _)).

% Moving (board)

move(piece(man, Color, From), ToPiece) :-
  neighbors(To, From, Direction),
  moves_towards_the(Color, ColorDirection),
  direction(ColorDirection, Direction),
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
  capture(FromPiece, ToPiece, Captured),
  ToPiece = piece(_, _, To),
  FromPiece = piece(_, _, From),
  findall(P, pieces_between(From, To, P, Board), Pieces),
  length(Pieces, 1),
  \+ member(piece(_, _, To), Board),
  member(Captured, Board).

capture(From, To, Captured, Board, BoardOut) :-
  capture(From, To, Captured, Board),
  exclude(=(Captured), Board, B1),
  replace(From, To, B1, BoardOut).

captures([From, To], Board, BoardOut) :-
  capture(From, To, _, Board, BoardOut).

captures([From,To|Rest], Board, BoardOut) :-
  capture(From, To, _, Board, BoardNext),
  captures([To|Rest], BoardNext, BoardOut).

captures(Captures, Board) :-
  captures(Captures, Board, _).

length_equals(V, L) :-
  length(L, LL),
  LL =\= V.

longest(Lists, ListsOut) :-
  maplist(length, Lists, X),
  max_list(X, Y),
  exclude(length_equals(Y), Lists, ListsOut).

options(Options) :-
  board(Board),
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

option(Option, Options, turn(From, To)) :-
  member(Option, Options),
  Option = [piece(_, _, From)|_],
  last(Option, ToPiece),
  ToPiece = piece(_, _, To),
  !.

% perform([Move|Moves], Board) :-
%   option(Option, Options, Move),
%   turn(Action,
%   perform(Option,

% used for capturing

replace(_, _, [], []).
replace(O, R, [O|T], [R|T2]) :- replace(O, R, T, T2).
replace(O, R, [H|T], [H|T2]) :- H \= O, replace(O, R, T, T2).
