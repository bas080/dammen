% # PDN parser and strinfifier.
%
% TODO: add headers to all files with author and website and stating that the
% software is copyrighted.
%
% Make it support char codes instead

% ## PDN object
%
% These define the name and the pattern which PDN objects follow.

pdn_object(spaces, [space]).
pdn_object(tag_pair, [char("["), text, space, quoted, char("]"), end_of_line]).
pdn_object(turn, [a_field, turn_sep, a_field, space]).
pdn_object(comment, [char(";"), text, end_of_line]).
pdn_object(comment, [char("{"), text, char("}")]).
pdn_object(numbered, [a_field, char(".")]).
% pdn_object(result(white), [char("1"), char("-"), char("0"), space]).
% pdn_object(result(black), [char("0"), char("-"), char("1"), space]).
% pdn_object(result(draw), [string_equals("1/2"), char("-"), string_equals("1/2"), space]).
pdn_object(unparsed, [ignored]).

% ## PDN objects
%
% Takes a string and turns it into a list of pdn objects.

pdn_objects("", []) :- !.

pdn_objects(String, [pdn_object(Type, Matched)|Types]) :-
  once((
    pdn_object(Type, Pattern),
    matches(String, Pattern, Matched, Left)
  )),
  pdn_objects(Left, Types).

matches(Unmatched, [], [], Unmatched) :- !.

matches(String, [Matcher|Rest], [Matched|MatchedRest], Unmatched) :-
  match(String, Matcher, Matched, Left),
  matches(Left, Rest, MatchedRest, Unmatched).

match(String, Matcher, Matched, Left) :-
  string_concat(Matched, Left, String),
  call(Matcher, Matched).

% ## PDN stringify
%
% Simply takes a previous parsed input and converts it back.
%
% TODO: write a test that validates this.
% pdn_objects(Input, Matches),
% pdn_stringify(Matches, Stringified),
% Input = Stringified.

pdn_stringify([], '') :- !.

pdn_stringify([pdn_object(_, [])|Types], Stringified) :-
  pdn_stringify(Types, Stringified).

pdn_stringify([pdn_object(Type, [Str|StrRest])|Types], Stringified) :-
  pdn_stringify([pdn_object(Type, StrRest)|Types], Rest),
  string_concat(Str, Rest, Stringified).

% ## Helpers
%
% Used for defining the pdn object patterns.

char(A, B) :-
  A = B.

quoted(String) :-
  matches(String, [char("\""), text, char("\"")], _, _).

ignored(A) :-
  string_length(A, 1).

string_equals(A, B) :-
  A = B.

text(A) :-
  \+ end_of_line(A).

token(A) :-
  tokenize_atom(A, [B]),
  A \= B.

a_field(A) :-
  number_string(B, A),
  B > 0.

end_of_line(A) :-
  string_length(A, 1),
  char_type(A, end_of_line).

space(A) :-
  string_length(A, 1),
  char_type(A, space).

turn_sep("-").
turn_sep("x").
