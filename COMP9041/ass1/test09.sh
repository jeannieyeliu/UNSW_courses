#!/bin/sh
#13.8
legit.pl init
touch a b
legit.pl add a b
legit.pl commit -m "first commit"
rm a
legit.pl commit -m "second commit"
legit.pl add a
legit.pl commit -m "second commit"
legit.pl rm --cached b
legit.pl commit -m "second commit"
legit.pl rm b
legit.pl add b
legit.pl rm b
legit.pl commit -m "third commit"
legit.pl rm b
legit.pl commit -m "fourth commit"
