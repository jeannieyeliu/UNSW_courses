#!/bin/sh
#16.5
legit.pl init
echo hello >a
legit.pl add a
legit.pl commit -m commit-0
legit.pl rm a
legit.pl status
legit.pl commit -m commit-1
legit.pl status
echo world >a
legit.pl status
legit.pl commit -m commit-2
legit.pl add a
legit.pl commit -m commit-2
legit.pl rm a
legit.pl commit -m commit-3
legit.pl show :a
legit.pl show 0:a
legit.pl show 1:a
legit.pl show 2:a
legit.pl show 3:a
legit.pl show 4:a
