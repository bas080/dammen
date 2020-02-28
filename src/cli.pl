#!/usr/bin/env swipl

piece_char(man, black, "⛀").
piece_char(man, white, "⛂").
piece_char(king, black, "⛁").
piece_char(king, white, "⛃").

piece_chars(P, X, Board) :-
  member(piece(T, C, X), Board)
  -> piece_char(T, C, P)
  ; P = ".".

offset_char(1, "   ", " \n").
offset_char(0, " ", "   \n").

split_list(Left, N, Right, Total) :-
  append(Left, Right, Total),
  length(Left, N),
  N > 0.

pp_fields([], "") :- !.

pp_fields(Fields, Str) :-
  split_list(L, 5 , Rest, Fields),
  length(Rest, N),
  dammen:row_direction_offset(Offset, N),
  offset_char(Offset, Left, Right),
  format(atom(Pieces), ' ~w   ~w   ~w   ~w   ~w ', L),
  parse:wrap(Pieces, Wrapped, Left, Right),
  pp_fields(Rest, RestPieces),
  string_concat(Wrapped, RestPieces, Str).

pp_board(Board) :-
  findall(P, (
    dammen:field(X),
    piece_chars(P, X, Board)
  ), Chars),
  pp_fields(Chars, Str),
  writeln(Str).

is_turn(Turn) :-
  Turn = turn(_, _).

color_turns([], []).

color_turns([turn(A, B)], [turn(A, B, white)]) :- !.

% Consider making this part of the parsing step.
color_turns(
  [turn(A, B), turn(C, D)|Rest],
  [turn(A, B, white), turn(C, D, black)|Colored]) :-
  color_turns(Rest, Colored).

main(Argv) :-
  nth0(1, Argv, File),
  writeln(File),
  read_file_to_codes(File, Codes, []),
  parse:parse_pdn(Objects, Codes),
  include(is_turn, Objects, Turns),
  color_turns(Turns, Colored),
  dammen:perform(Colored, _).

  % dammen:perform(Colored, Out).
  % pp_board(Out),
  % writeln(Out).


%validate_moves([Move|Moves
