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
  neighbors(A, B, D).

neighbors(A, B, D) :-
  field(A),
  field(B),
  direction_of(D, B),
  row_parity_of(T, B),
  movement(D, T, I),
  A is B + I.

% Pieces

piece(white).
piece(black).

men(white).
men(black).

initial_piece_of(white, X) :-
  field(X),
  X > 30.

initial_piece_of(black, X) :-
  field(X),
  X < 21.

initial_piece_of(none, X) :-
  \+ initial_piece_of(white, X),
  \+ initial_piece_of(black, X).

initial_board(P) :-
  findall(C, (
    field(A),
    initial_piece_of(C, A)
  ), P).

% Moves

shares_line(A, B, D) :-
  neighbors(C, B, D),
  (A is C; shares_line(A, C, D)).

%TBD: make them obey the north or south direction.
valid_moves(piece(_), A, B) :-
  neighbors(A, B, D).

valid_moves(men(_), A, B) :-
  shares_line(A, B, _).

% return which this is captured
valid_captures(piece(_), A, B) :-
  neighbors(B, A, D),
  neighbors(_, B, D).

valid_captures(men(_), A, B) :-
  shares_line(B, A, D),
  neighbors(_, B, D).

% Capture

% helper
replace(L, I, X, R) :-
    Dummy =.. [dummy|L],
    setarg(I, Dummy, X),
    Dummy =.. [dummy|R].

moves_to(A, B, B1, B2) :-
  nth(A, B1, AC),
  nth(B, B1, BC),
  piece(AC),
  \+ piece(BC),
  field(A),
  field(B),
  valid_moves(piece(AC), A, B),
  replace(B1, A, none, B3),
  replace(B3, B, AC, B2).

captures(A, B, P) :-
  neighbors(A, C),
  neighbors(B, C),
  nth(A, P, Pa),
  nth(B, P, Pb),
  nth(C, P, Pc),
  piece(Pa),
  piece(Pb),
  Pa \= Pb,
  \+ piece(Pc).

parse_move_type("-").
parse_move_type("x").

parse_move(Move, A, B, C) :-
  parse_move_type(C),
  append(C, B, N),
  append(A, N, Move).

