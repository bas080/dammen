% Parsing a PDN file.

parse_move_type(move, "-").
parse_move_type(capture, "x").

parse_movetext_comment(comment(Comment), Text) :-
  wrap(Comment, Text, "{", "}").

% TODO: Not yet implemented. (No newline in normalized text)
parse_movetext_comment(comment(Comment), Text) :-
  wrap(Comment, Text, ";", "\n").

parse_tag_pair(tag_pair(TagPair), Text) :-
  wrap(TagPair, Text, "[", "]").

result("1-0").
result("0-1").
result("1/2-1/2").

parse_movetext_result(result(Text), Text) :-
  result(Text).

parse_movetext_number(number(Number), Text) :-
  number_string(Number, Text).

parse_movetext_capture(capture(From, To), Text) :-
  field(From),
  field(To),
  wrap("x", Text, From, To).

parse_movetext_move(move(From, To), Text) :-
  field(From),
  field(To),
  wrap("-", Text, From, To).

parse_movetext_move(Move, Text) :-
  string_concat(WithoutAsterisk, "*", Text),
  parse_movetext_move(Move, WithoutAsterisk).

parse_pdn(Objects, Codes) :-
  parse_pdn_strict(StrictObjects, Codes)
  -> Objects = StrictObjects
  ;  parse_pdn_flexible(Objects, Codes).

parse_pdn_strict([], []) :- !.

parse_pdn_strict(Objects, Codes) :-
  parse_pdn_object(Object, Codes, Rest)
  -> (parse_pdn(RestObjects, Rest), Objects = [Object|RestObjects])
  ;  (
    write("parse-warning: "),
    fail
  ). % Objects = [unparsed(Codes)].

parse_pdn_small(Objects, Codes) :-
  parse_pdn_strict(Objects, Codes)
  -> true
  ;  (
    Codes = [_|Rest],
    parse_pdn_small(Objects, Rest)
  ).

parse_pdn_flexible([], []) :- !.

parse_pdn_flexible(Objects, Codes) :-
  parse_pdn_object(Object, Codes, Rest)
  -> (
    parse_pdn_flexible(RestObjects, Rest),
    Objects = [Object|RestObjects]
  ) ; (
    Codes = [Drop|KeepReading],
    char_code(Char, Drop),
    write("Dropped char: "),
    writeln(Char),
    parse_pdn_flexible(Objects, KeepReading)
  ).

parse_pdn_object(Object, Codes, Rest) :-
  split_list(Left, Rest, Codes),
  string_codes(Text, Left),
  token(String, Text),
  (
    parse_tag_pair(Object, String);
    parse_movetext_number(Object, String);
    parse_movetext_move(Object, String);
    parse_movetext_capture(Object, String);
    parse_movetext_result(Object, String);
    parse_movetext_comment(Object, String)
  ),
  !.

% HELPERS
token(Token, Text) :-
  token_separator(Right),
  (token_separator(Left); Left = ""),
  wrap(Untrimmed, Text, Left, Right),
  trim(Token, Untrimmed).

token_separator("\n").
token_separator(" ").
token_separator(".").

trim(Trimmed, Text) :-
  normalize_space(atom(X), Text),
  atom_string(X, Trimmed).

% handy helper (should check if this can be improved.
% Maybe use format here
wrap(Str, Surrounded, Start, After) :-
  catch((
    string_concat(Str, After, B),
    string_concat(Start, B, Surrounded)),
    error(_, _), (
    string_concat(Start, B, Surrounded),
    string_concat(Str, After, B))).

split_list(Left, N, Right, Total) :-
  append(Left, Right, Total),
  length(Left, N),
  N > 0.

split_list(Left, Right, Total) :-
  split_list(Left, _, Right, Total).

field(X) :-
  between(1, 50, X).
