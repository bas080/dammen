# Dammen

An implementation for validating the legality of a Draughts move.

## Goals

1. The intention is to support [PDN][1] files. These are fed into the program
   and validated. The program will exit successfully when the PDN file is
   completely valid.

2. Build a simple CLI client for printing board and editing the PDN file
   (Making a move).

3. Make a server that will host one or more games and ties into the CLI tool.
   (Basically hosts the PDN files and allows players of the match to update the
   PDN file).

## Tasks

- https://www.swi-prolog.org/FAQ/PrologScript.html
- consider changing piece to piece(man/king, black/white, Field).

## Credits

Ik wijd deze software toe aan Rom. Dankjewel voor het opnieuw ontwekken van mijn
liefde voor het bordspel.

[1]: https://en.wikipedia.org/wiki/Portable_Draughts_Notation
