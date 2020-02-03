% Board

field(X) :-
  between(1, 50, X).

row_of(I, A) :-
  I is ceiling(A / 5).

row_parity_of(odd, A) :-
  row_of(I, A),
  mod(I, 2) =:= 1.

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

direction_of(sw, A) :-
  \+ borders(A, bottom),
  \+ borders(A, left).

direction_of(se, A) :-
  \+ borders(A, bottom),
  \+ borders(A, right).

direction_of(nw, A) :-
  \+ borders(A, top),
  \+ borders(A, left).

direction_of(ne, A) :-
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
  direction_of(D, B),
  row_parity_of(T, B),
  movement(D, T, I),
  A is B + I.

% Pieces

man(white).
man(black).
man(Color, Field) :-
  field(Field),
  man(Color).

king(white).
king(black).
king(Color, Field) :-
  field(Field),
  king(Color).

piece(A) :-
  A = king(_);
  A = man(_);
  A = king(_, _);
  A = man(_, _).

% Board

initial_piece(man(white, X)) :-
  field(X),
  X > 30.

initial_piece(man(black, X)) :-
  field(X),
  X < 21.

initial_board(Board) :-
  findall(Piece, (
    initial_piece(Piece)
  ), Board).

% Turns

shares_line(A, B) :-
  shares_line(A, B, _).

shares_line(A, B, D) :-
  neighbors(C, B, D),
  (A is C; shares_line(A, C, D)).

move(man(black, From), Piece) :-
  neighbors(To, From, D),
  direction(south, D),
  becomes(
    man(black, To),
    Piece).

move(man(white, From), Piece) :-
  neighbors(To, From, D),
  direction(north, D),
  becomes(
    man(white, To),
    Piece).

move(king(Color, From), king(Color, To)) :-
  shares_line(From, To).

becomes(man(black, Field), king(black, Field)) :-
  field(Field),
  borders(Field, bottom).

becomes(man(white, Field), king(white, Field)) :-
  field(Field),
  borders(Field, top).

becomes(A, A) :-
  \+ becomes(A, king(_, _)).

filter(_,[],[]).
filter(Predicate,[First|Rest],[First|Tail]) :-
   filter(Predicate,Rest,Tail).
filter(Predicate,[_|Rest],Result) :-
   filter(Predicate,Rest,Result).

move(FromPiece, ToPiece, BoardIn, BoardOut) :-
  member(FromPiece, BoardIn),
  \+ member(ToPiece, BoardIn),
  move(FromPiece, ToPiece),
  filter(\=(FromPiece), BoardIn, C),
  append([ToPiece], C, BoardOut).

capture(man(Color, From), man(Color, To)) :-
  neighbors(C, From, D),
  neighbors(To, C, D).

capture(king(Color, From), king(Color, To)) :-
  shares_line(C, From, D),
  neighbors(To, C, D).

% Capture

% helper
%replace(L, I, X, R) :-
%    Dummy =.. [dummy|L],
%    setarg(I, Dummy, X),
%    Dummy =.. [dummy|R].

% TBD: returns the valid moves
%valid_turn(From, To, TurnType) :-
%  todo.

parse_move_type(move, "-").
parse_move_type(capture, "x").

parse_token(Token, Text) :-
  (
    append(Token, " ", T),
    append(T, Rest, Text)
  ); parse_token(Token, Rest).

parse_move(Turn, FromN, ToN, Move) :-
  field(FromN),
  field(ToN),
  number_codes(FromN, From),
  number_codes(ToN, To),
  parse_move_type(Move, MoveChar),
  append(MoveChar, To, Start),
  append(From, Start, Turn).
