% TODO: optimize by moving to more piece oriented approach. This reduces the
% amount of possibilities to the pieces on the board firstly. member(Piece,
% Board).

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
  field(A),
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

% Board: creating the initial board

board_piece(piece(man, white, X)) :-
  field(X),
  X > 30.

board_piece(piece(man, black, X)) :-
  field(X),
  X < 21.

board(Board) :-
  findall(Piece, board_piece(Piece), Board), !.

random_piece(P) :-
  P = piece(Piece, Color, Field),
  color(Color),
  piece(Piece),
  field(Field).

random_board(Board) :-
  findall(P, (random_piece(P)), Pieces),
  between(5, 20, N),
  permutation(Pieces, Rand),
  findnsols(N, Piece, member(Piece, Rand), Board).

test_board(X) :-
  X = [
    piece(man, black, 13),
    piece(man, white, 18),
    piece(man, white, 27)
  ].

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

moves_towards_the(black, south).
moves_towards_the(white, north).

king_side(black, bottom).
king_side(white, top).
promotes_to(A, B) :-
  (
    A = piece(man, Color, Field),
    king_side(Color, Border),
    borders(Field, Border)
  ) -> B = piece(king, Color, Field) ; B = A.

% # Move
%
% Both movement of men and kings

move(piece(man, Color, From), ToPiece) :-
  moves_towards_the(Color, ColorDirection),
  direction(ColorDirection, Direction),
  neighbors(To, From, Direction),
  promotes_to(piece(man, Color, To), ToPiece).

move(piece(king, Color, From), piece(king, Color, To)) :-
  shares_line_with(From, To).

move(FromPiece, ToPiece, Board) :-
  member(FromPiece, Board),
  move(FromPiece, ToPiece),
  ToPiece = piece(_, _, To),
  FromPiece = piece(_, _, From),
  \+ pieces_between(From, To, _, Board), % is only required when piece is a king
  \+ member(piece(_, _, To), Board).

move(FromPiece, ToPiece, BoardIn, BoardOut) :-
  move(FromPiece, ToPiece, BoardIn),
  subtract([ToPiece|BoardIn], [FromPiece], BoardOut).

pieces_between(From, To, Piece, Board) :-
  shares_line_with(From, Middle, D),
  shares_line_with(Middle, To, D),
  member(Piece, Board),
  Piece = piece(_, _, Middle).

% # Capture (single piece)
%
% These are the building blocks for capturing multiple pieces.

% TODO: abstract the neighbors and shares_line_with into an Op
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
  \+ member(piece(_, _, To), Board),
  FromPiece = piece(_, _, From),
  once(findnsols(2, P, pieces_between(From, To, P, Board), Pieces)),
  length(Pieces, 1).

% Keep the captured piece on the board. This is required in order to comply
% with certain capture cases.
capture(FromPiece, ToPiece, Captured, Board, BoardOut) :-
  capture(FromPiece, ToPiece, Captured, Board),
  subtract([ToPiece|Board], [Captured, FromPiece], BoardOut).

% # Captures (multiple pieces)
%
% These rules are used for both single and multiple piece capture.

captures(From, To, [A|Rest], Board, BoardOut) :-
  capture(From, Next, A, Board, B1),
  captures(Next, To, Rest, B1, BoardOut).

captures(From, To, [A], Board, BoardPromoted) :-
  capture(From, To, A, Board, BoardOut),
  maplist(promotes_to, BoardOut, BoardPromoted). % Does it make sense to itterate over all of this.

% dun know what to name this stuff. Consider refactoring the options fn to
% remove this temporary data
options_capture([From,To|_], capture(From, To)).

% # Options
%
% These functions are used to compute the valid moves/captures a player is
% allowed to do.

% TODO: Check if there is longest king move otherwise all.
options(Board, Color, Options) :-
  findall(
    Result,
    (
      From = piece(_, Color, _),
      captures(From, To, Captured, Board, _),
      Result = [From, To|Captured]
    ),
    Captures
  ),
  \+ length(Captures, 0),
  longest(Captures, Longest),
  maplist(options_capture, Longest, Options),
  !.

options(Board, Color, Options) :-
  findall(move(From, To), (
     move(From, To, Board),
    From = piece(_, Color, _)
  ), Options).

perform(A, BoardOut) :-
  board(Board),
  perform(A, Board, BoardOut).

perform(capture(From, To), Board, BoardOut) :-
  captures(From, To, _, Board, BoardOut).

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

option(_, T, _) :-
  writeln(T),
  fail.

option(Options, turn(From, To, Color), Option) :-
  member(Option, Options),
  Option = move(piece(_, Color, From), piece(_, Color, To)),
  !.

option(Options, turn(From, To, _), Option) :-
  member(Option, Options),
  Option = capture(piece(_, _, From), piece(_, _, To)),
  !.

% # Helpers

length_equals(V, L) :-
  length(L, LL),
  LL =\= V.

longest(Captures, Longest) :-
  maplist(length, Captures, X),
  max_list(X, Y),
  exclude(length_equals(Y), Captures, Longest).
