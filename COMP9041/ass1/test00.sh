#!/bin/bash

#test subset 0;
cleanAll(){
	rm [a-zA-Z_]+;
	if test -e .legit
	then
		rm -rf .legit;
	fi;
}


#Test1 init 
cleanAll;
./legit.pl init


#Test2 init with existing repo
cleanAll;
mkdir .legit
./legit.pl init


#Test3 add with no previous init
cleanAll;
touch a
./legit.pl add a

#Test4 add with non-existent file
cleanAll;
./legit.pl init
./legit.pl add non_existent_file

#Test5 (add, commit, show) 
cleanAll;

The correct 12 lines of output for this #Testwere:
cleanAll;
./legit.pl init
echo 1 >a
./legit.pl add a
echo 2 >a
./legit.pl commit -m message
echo 3 >a
./legit.pl show 0:a
./legit.pl show :a

#Test6 (show) 
cleanAll;
./legit.pl init
echo line 1 >a
echo hello world >b
./legit.pl add a b
./legit.pl commit -m "first commit"
echo line 2 >>a
./legit.pl add a
./legit.pl commit -m "second commit"
./legit.pl log
echo line 3 >>a
./legit.pl add a
echo line 4 >>a
./legit.pl show 0:a
./legit.pl show 1:a
./legit.pl show :a
./legit.pl show 0:b
./legit.pl show 1:b

#Test7 (show errors)
cleanAll;
./legit.pl init
echo line 1 >a
echo hello world >b
./legit.pl add a b
./legit.pl commit -m "first commit"
./legit.pl show :c
./legit.pl show 0:c
./legit.pl show 2:a

#Test8 (add, commit, no change, commit,)
cleanAll;
./legit.pl init
echo 1 >a
./legit.pl add a
./legit.pl commit -m message1
touch a
./legit.pl add a
./legit.pl commit -m message2