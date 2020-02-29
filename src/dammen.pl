% # Fields
%
% Describes the fields and the relations between them.

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

borders(A, top) :-
  A < 6.

borders(A, bottom) :-
  A > 45.

movement(sw, 4).
movement(ne, -5).
movement(se, 5).
movement(nw, -6).

neighbors(A, B, D) :-
  field(A),
  field(B),
  movement(D, I),
  row_direction_offset(Offset, B),
  A is (B + Offset + I),
  \+ row_direction_offset(Offset, A).

shares_line_with(A, B, D) :-
  neighbors(A, B, D).

shares_line_with(A, B, D) :-
  neighbors(A, C, D),
  shares_line_with(C, B, D).

% # Pieces
%
% Describes the different colors and types of pieces.

color(white, black).
color(black, white).
color(white).
color(black).

piece(man).
piece(king).
piece(Piece, Color, Field) :-
  color(Color),
  piece(Piece),
  field(Field).

moves_towards(black, south).
moves_towards(white, north).

king_side(black, bottom).
king_side(white, top).

% # Board
%
% Utilities for generating boards

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

% # Promote
%
% When a man reaches the other side of the board it becomes a king.

promotes(A, B) :-
  (
    A = piece(man, Color, Field),
    king_side(Color, Border),
    borders(Field, Border)
  ) -> B = piece(king, Color, Field) ; B = A.

% # Move
%
% Both movement of men and kings

move(piece(man, Color, From), ToPiece) :-
  moves_towards(Color, ColorDirection),
  direction(ColorDirection, Direction),
  neighbors(To, From, Direction),
  promotes(piece(man, Color, To), ToPiece).

move(piece(king, Color, From), piece(king, Color, To)) :-
  shares_line_with(From, To, _).

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
%
% The capturing uses a little trick where the captured piece color is inverted,
% preventing it from being eaten again.

capture_operation(man, neighbors).
capture_operation(king, shares_line_with).

capture(piece(A, C, From),
        piece(A, C, To),
        piece(_, Opposite, Middle)) :-
  capture_operation(A, Operation),
  call(Operation, From, Middle, Direction),
  call(Operation, Middle, To, Direction),
  color(C, Opposite).

capture(FromPiece, ToPiece, Captured, Board) :-
  member(FromPiece, Board),
  member(Captured, Board),
  capture(FromPiece, ToPiece, Captured),
  ToPiece = piece(_, _, To),
  \+ member(piece(_, _, To), Board),
  FromPiece = piece(_, _, From),
  once(findnsols(2, P, pieces_between(From, To, P, Board), Pieces)),
  length(Pieces, 1).

capture(FromPiece, ToPiece, Inverted, Board, BoardOut) :-
  capture(FromPiece, ToPiece, Captured, Board),
  invert(Captured, Inverted),
  subtract([ToPiece,Inverted|Board], [Captured, FromPiece], BoardOut).

invert(piece(T, C, F), piece(T, Co, F)) :-
  color(C, Co).

% # Captures (multiple pieces)
%
% These rules are used for both single and multiple piece capture.

captures(From, To, [A|Rest], Board, BoardOut) :-
  capture(From, Next, A, Board, B1),
  captures(Next, To, Rest, B1, B2),
  subtract(B2, [A], BoardOut).

captures(From, To, [A], Board, BoardOut) :-
  capture(From, To, A, Board, B),
  subtract(B, [A], B1),
  maplist(promotes, B1, BoardOut).

% # Options
%
% These functions are used to compute the valid moves/captures a player is
% allowed to do.

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
  options_priority(Captures, Prioritized),
  maplist(options_capture, Prioritized, Options),
  !.

% TODO: refactor so it looks nicer
options_capture([From,To|_], capture(From, To)).

is_king_capture(Captures) :-
  A = piece(king, _, _),
  Captures = [A];
  Captures = [A|_].

options_priority(Options, Prioritized) :-
  longest(Options, Longest),
  include(is_king_capture, Longest, Kings)
    -> Prioritized = Kings
    ;  Prioritized = Options.

options(Board, Color, Options) :-
  findall(move(From, To), (
     move(From, To, Board),
    From = piece(_, Color, _)
  ), Options).

% # Option
%
% Convert a turn to an option.
% TODO: Consider merging this function with the options function

option(Options, turn(From, To, Color), Option) :-
  member(Option, Options),
  (
    Option = move(piece(_, Color, From), piece(_, Color, To));
    Option = capture(piece(_, Color, From), piece(_, Color, To))
  ),
  !.

% # Perform
%
% Functions that take the current board, a move and return the new board.

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

% # Helpers

length_equals(V, L) :-
  length(L, LL),
  LL =\= V.

longest(Captures, Longest) :-
  maplist(length, Captures, X),
  max_list(X, Y),
  exclude(length_equals(Y), Captures, Longest).
