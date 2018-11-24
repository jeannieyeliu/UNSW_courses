#!/bin/sh
#this test is to test if the file is legit removable and the legit status after the removal

#1. test if the file is removable
#files:
#a: local same as index, index same as repo
#b: 


#actions:
#legit rm
#legit --cached rm
# file	local=repo?	local = index?	index=repo?
# a0	0			0				0
# a1	0			0				1
# a2	0			1				0
# a3	1			1				1
# a4	1			0				0

# file	local content	index content	repo content
# a0	111				11				1
# a1	111				11				11
# a2	11				11				1
# a3	1				1				1
# a4	1				11				1
# a5	only in index
# a6 	only in index
cleanAll(){
	rm a*;
	if test -e .legit
	then
		rm -rf .legit;
	fi;
}

cleanAll;



createFile(){
    ./legit.pl init;

	echo 1>a0;
	echo 1>a1;
	echo 1>a2; 
	echo 1>a3;
	echo 1>a4;
	echo 1>a5;
	echo 1>a6; 
	echo 1>a7; 

	./legit.pl add a0 a1 a2 a3 a4 a5 ;

	./legit.pl commit -m 'commit 0';

	./legit.pl add a6 a7;

	echo 1>>a0;
	echo 1>>a2;
	echo 1>>a4;

	./legit.pl add a0 a2 a4;


	echo 1>>a1;
	echo 1>>a5;

	echo 1>>a0;
}


rmSystem(){
	rm a*;
}

legitRmCachedAll(){
	./legit.pl rm --cached a0;
	./legit.pl rm --cached a1;
	./legit.pl rm --cached a2;
	./legit.pl rm --cached a3;
	./legit.pl rm --cached a4;
	./legit.pl rm --cached a5;
	./legit.pl rm --cached a6;
	./legit.pl rm --cached a7;
}

legitRmCachedForceAll(){
	./legit.pl rm --cached --force a0;
	./legit.pl rm --cached --force a1;
	./legit.pl rm --cached --force a2;
	./legit.pl rm --cached --force a3;
	./legit.pl rm --cached --force a4;
	./legit.pl rm --cached --force a5;
	./legit.pl rm --cached --force a6;
	./legit.pl rm --cached --force a7;
}


legitRmAll(){
	./legit.pl rm a0;
	./legit.pl rm a1;
	./legit.pl rm a2;
	./legit.pl rm a3;
	./legit.pl rm a4;
	./legit.pl rm a5;
	./legit.pl rm a6;
	./legit.pl rm a7;
}

legitAddAll(){
	./legit.pl add a0;
	./legit.pl add a1;
	./legit.pl add a2;
	./legit.pl add a3;
	./legit.pl add a4;
	./legit.pl add a5;
	./legit.pl add a6;
	./legit.pl add a7;
}

legitCommitAll(){
	./legit.pl commit -m 'commit comment';
}

#test 1 create file with different existance in index,local, repo
echo "========test0: create file========";
createFile;
./legit.pl statusBitOr

#test 2 create file with different existance in index,local, repo, them rm 
echo "========test1: rm  ========";
cleanAll;
createFile;
./legit.pl statusBitOr

echo "========test1:rm all files=======";
rmSystem;
./legit.pl statusBitOr
echo "========test1: after rm: legit add all files :=======";
legitAddAll;
./legit.pl statusBitOr
echo "========test1: after rm,add:legit commit all files=======";
legitCommitAll
./legit.pl statusBitOr


#test 2 create file with different existance in index,local, repo, them legit rm 
echo "========test2: legit rm  ========";
cleanAll;
createFile;

echo "========test2: legit rm all files=======";
legitRmAll;
./legit.pl statusBitOr
echo "========test2: legit legit rm , add all files=======";
legitAddAll;
./legit.pl statusBitOr
echo "========test2: legit legit rm , add , commit all files=======";
legitCommitAll
./legit.pl statusBitOr


#test 3 create file with different existance in index,local, repo, them legit rm --cached 
echo "========test3: legit rm --cached  ========";
cleanAll;
createFile;

echo "========test3: legit rm --cached all files=======";
legitRmCachedAll;
./legit.pl statusBitOr
echo "========test3: legit rm --cached, add all files=======";
legitAddAll;
./legit.pl statusBitOr
echo "========test3: legit rm --cached, add commit all files=======";
legitCommitAll
./legit.pl statusBitOr


#test 4 create file with different existance in index,local, repo, them legit rm --cached 
echo "========test4: legit rm --cached  --force  ========";
cleanAll;
createFile;

echo "========test4: legit rm --cached --force all files=======";
legitRmCachedForceAll;
./legit.pl statusBitOr
echo "========test4: legit rm --cached  --force , add all files=======";
legitAddAll;
./legit.pl statusBitOr
echo "========test4: legit rm --cached  --force , add commit all files=======";
legitCommitAll
./legit.pl statusBitOr


