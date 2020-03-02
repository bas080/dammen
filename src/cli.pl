#!/usr/bin/env swipl

% % % % % % %
% author:  Bas Huis
% github:  https://github.com/bas080
% created: Mon Mar  2 19:59:23 CET 2020
% license: GNU General Public License 3.0
% % % %

% TODO: Can use a good rewrite.

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
  Turn = pdn_object(turn, _).

to_turn(pdn_object(turn, [From, _, To|_]), turn(FromS, ToS)) :-
  number_string(FromS, From),
  number_string(ToS, To).

color_turns([], []).

color_turns([turn(A, B)], [turn(A, B, white)]) :- !.

% Consider making this part of the parsing step.
color_turns(
  [turn(A, B), turn(C, D)|Rest],
  [turn(A, B, white), turn(C, D, black)|Colored]) :-
  color_turns(Rest, Colored).

main(Argv) :-
  nth0(1, Argv, File),
  read_file_to_string(File, String, []),
  pdn_objects(String, Objects),
  include(is_turn, Objects, A),
  maplist(to_turn, A, Turns),
  color_turns(Turns, Colored),
  dammen:perform(Colored, _).

wrap(Str, Surrounded, Start, After) :-
  catch((
    string_concat(Str, After, B),
    string_concat(Start, B, Surrounded)),
    error(_, _), (
    string_concat(Start, B, Surrounded),
    string_concat(Str, After, B))).
