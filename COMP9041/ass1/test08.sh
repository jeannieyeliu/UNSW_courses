#!/bin/sh

#14.7
legit.pl init
echo 1 >a
echo 2 >b
echo 3 >c
legit.pl add a b c
legit.pl commit -m "first commit"
echo 4 >>a
echo 5 >>b
echo 6 >>c
echo 7 >d
echo 8 >e
legit.pl add b c d
echo 9 >b
legit.pl rm a
legit.pl rm b
legit.pl rm c
legit.pl rm d
legit.pl rm e
legit.pl rm --cached a
legit.pl rm --cached b
legit.pl rm --cached c
legit.pl rm --cached d
legit.pl rm --cached e
legit.pl rm --force a
legit.pl rm --force b
legit.pl rm --force c
legit.pl rm --force d
legit.pl rm --force e
