% Parsing a PDN file.
% - Make parsing quicker than ~half a second
% - Implement stringify pdn feature

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
result("1-1").

parse_movetext_result(result(Text), Text) :-
  result(Text).

parse_movetext_number(number(Number), Text) :-
  wrap(Number, Text, "", ".").

parse_movetext_turn(turn(From, To), Text) :-
  (Middle = "-"; Middle = "x"),
  dammen:field(From),
  dammen:field(To),
  wrap(Middle, Text, From, To), !.

% Forced moves might have an *
parse_movetext_turn(Move, Text) :-
  string_concat(WithoutAsterisk, "*", Text),
  parse_movetext_turn(Move, WithoutAsterisk).

parse_pdn([], []) :- !.

parse_pdn(Objects, Codes) :-
  parse_pdn_object(Object, Codes, Rest)
  -> (parse_pdn(RestObjects, Rest), Objects = [Object|RestObjects])
  ;  (
    parse_pdn_flexible(Objects, Codes)
  ). % Objects = [unparsed(Codes)].

parse_pdn_string(Objects, String) :-
  writeln(String),
  string_codes(String, Codes),
  parse_pdn(Objects, Codes).

parse_pdn_flexible([], []) :- !.

parse_pdn_flexible(Objects, Codes) :-
  parse_pdn_object(Object, Codes, Rest)
  -> (
    parse_pdn(RestObjects, Rest),
    Objects = [Object|RestObjects]
  ) ; (
    Codes = [_|KeepReading],
    parse_pdn_flexible(Objects, KeepReading)
  ).

pdn_object_string(Object, String) :-
  once(
    parse_movetext_number(Object, String);
    parse_movetext_result(Object, String);
    parse_movetext_turn(Object, String);
    parse_movetext_comment(Object, String)
  ).

pdn_string([], "") :- !.

pdn_string([Object|Objects], String) :-
  pdn_object_string(Object, ObjectString),
  string_concat(ObjectString, "\n", WithNL),
  pdn_string(Objects, RestString),
  string_concat(WithNL, RestString, String).

parse_pdn_object(Object, Codes, Rest) :-
  append(Left, Rest, Codes),
  string_codes(Text, Left),
  token(String, Text),
  pdn_object_string(Object, String),
  !.

% HELPERS
token(Token, Text) :-
  token_separator(Right),
  (token_separator(Left); Left = ""),
  wrap(Untrimmed, Text, Left, Right),
  trim(Token, Untrimmed).

token_separator("\n").
token_separator(" ").
% token_separator(".").

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
