#!/usr/bin/perl -w

use strict;
use warnings;
use File::Copy;
use Fcntl;
use File::Compare;
my $usage='Usage: legit.pl <command> [<args>]

These are the legit commands:
   init       Create an empty legit repository
   add        Add file contents to the index
   commit     Record changes to the repository
   log        (Show) commit log
   show       Show file at particular state
   rm         Remove files from the current directory and from the index
   status     Show the status of files in the current directory, index, and repository
   branch     list, create or delete a branch
   checkout   Switch branches or restore current directory files
   merge      Join two development histories together'."\n";


#if there's no argument, print usage
unless (exists($ARGV[0])){
	print $usage;
   	exit 0;
}

#================      define global variables        ============
my $cmd = shift @ARGV;
my $legitDir = ".legit";					#the legit repo
my $indexFile = ".legit/index";				#index file, store the add info in the buffer
my $headFile = ".legit/HEAD";				#points to current branch in the ref/heads folder
my $objectDir = ".legit/object";				#stores all the files by add and commit
my $objectMasterDir = ".legit/object/master";		#stores specify the dirname of the add buffer
my $refDir = ".legit/ref";					#
my $refHeadsDir = ".legit/ref/heads";		#store the branch info
my $refTagDir =  ".legit/ref/tag";			#store the commit info
my $logHeadFile = ".legit/logs/HEAD";		#the branch switch log file
my $logRefDir = ".legit/logs/ref";			#store the commit log for each branch

#================ begin processing command line input ============
if ($cmd eq 'init'){
	if (@ARGV == 0) {
		init();
	}else{
		print "usage: legit.pl init\n";
	}
	exit 0;
}

elsif ($cmd eq 'add'){
	checkInit();

	if (@ARGV == 0){
		print "usage: legit.pl add <files>\n";
		exit 1;
	}
	add(@ARGV);
}

elsif ($cmd eq 'commit'){
	checkInit();
	my $usg = "usage: legit.pl commit [-a] -m commit-message\n";
	my $a_flag = 0;
	my $cmmt_msg;
	if ( @ARGV == 2 and $ARGV[0] eq '-m') {
		$cmmt_msg = $ARGV[1];
	} elsif ( @ARGV == 3 and $ARGV[0] eq '-a' and $ARGV[1] eq '-m' ) {
		$a_flag = 1;
		$cmmt_msg = $ARGV[2];
	} else{
		print "$usg";
		exit 1;
	}
	#commit message doesn't have a new line
	if ($cmmt_msg =~ /\n/){
		print "legit.pl: error: commit message can not contain a newline\n";
		exit 1;
	}

	# if -a 
	if ($a_flag) {
		commit_a($cmmt_msg);
	}else{
		commit($cmmt_msg);
	}

}

elsif ($cmd eq 'log'){
	checkInit();
	my $usg = "usage: legit.pl log\n";
	if (@ARGV != 0){
		print "$usg";
		exit 1;
	}
	getlog();
}

elsif ($cmd eq 'show'){
	checkInit();
	show($ARGV[0]);
}

elsif ($cmd eq 'rm'){
	checkInit();
	my $usg = "usage: legit.pl rm [--force] [--cached] <filenames>\n";
	my %options=("--force",0,"--cached",0);
	foreach my $arg (@ARGV){
		$options{$arg}=1;
	}

	my @rmFiles = @ARGV[($options{"--force"}+$options{"--cached"})..$#ARGV];
	
	foreach my $f (@rmFiles){
		checkValidFileName($f);
	}

	rm($options{"--force"},$options{"--cached"},@rmFiles);
}

elsif ($cmd eq 'status'){
	checkInit();
	my $usg = "usage: legit.pl status\n";
	if (@ARGV != 0){
		print "$usg";
		exit 1;
	}
	#status();
	printStatusBitOr();
}

elsif ($cmd eq 'branch'){
	checkInit();
	unless (-e $indexFile){
		print "legit.pl: error: your repository does not have any commits yet\n";
		exit 1;
	} 

	my $branchName = getCurrentBranchName();	
	my $lastCommitFile = "$refHeadsDir$branchName";
	unless (-e $lastCommitFile) {
		print "legit.pl: error: your repository does not have any commits yet\n";
		exit 1;
	}
	my $usg = "usage: legit.pl [-d] <branch>\n";
	#create branch
	if (@ARGV == 0){
		branchList();
	} elsif ($ARGV[0] =~/^[-]/ or @ARGV>2){
		print $usg;
	} elsif (@ARGV == 1){
		checkValidBranchName($ARGV[0]);
		branchCreate( $ARGV[0]);
	} elsif (@ARGV == 2 && $ARGV[0]=="-d"){
		checkValidBranchName($ARGV[1]);
		branchDelete( $ARGV[1]);
	} 
}

elsif ($cmd eq 'checkout'){
	checkInit();
	print "TODO call checkout function \n";

}

elsif ($cmd eq 'merge'){
	checkInit();
	print "TODO call merge function \n";
}

#only for test purpose
elsif ($cmd eq 'statusBitOr'){
	printStatusBitOr();
}

else{
	print "legit.pl: error: unknown command $cmd\n";
	print "$usage"
}

#================ end processing command line input ============

#================ Utility subroutine ====================
#test if string is in the arg list in(argname, arglist)
sub indexOfList{
	my $flag = shift @_;
	my @list = @_;
	foreach my $i (0..@_){
		return $i if $_[$i] eq $flag;
	}
	return 0;
}

sub checkValidFileName{
	my $f = $_[0];
	my $errMsg = "legit.pl: error: invalid filename '$f'\n";

	unless (lc $f =~ /^[a-z0-9][a-z0-9._-]*$/) {
		print "$errMsg";
		exit 1;
	}
}
sub checkValidBranchName{
	my $f = $_[0];
	my $errMsg = "legit.pl: error: invalid branch  name '$f'\n";

	unless (lc $f =~ /^[a-z0-9][a-z0-9._-]*$/) {
		print "$errMsg";
		exit 1;
	}
}
#get the content of HEAD file, i.e. the pointer that points to the current branch
sub getCurrentBranchRef{
	# read HEAD file
	open F, '<', $headFile or die "$0: Can't open $headFile: $!\n";
	my @line=<F>;
	my $branch = $line[0];
	close F;
	return $branch;
}
# return refs/tag/branchname folder
sub getCurrentBranchTag{
	my $currentBranchName = getCurrentBranchName();
	my $tagBranch = "$refTagDir$currentBranchName";
	return $tagBranch;
}

sub getCurrentBranchName{
	my $branchRef = getCurrentBranchRef();
	if ($branchRef =~ /ref: refs\/heads(.*)/g){
		return $1;
	}
	return $branchRef;
}

sub getLastCommitFile{
	my $branchName = getCurrentBranchName();	
	my $lastCommitFile = "$refHeadsDir$branchName";
	return $lastCommitFile;
}
sub getLastCommitInfo{
	my $branchName = getCurrentBranchName();
	
	my $commitFile = "$refHeadsDir$branchName";
	unless (-e $commitFile) {
		return "false";
	}
	open F, '<', $commitFile or die "$0: Can't open $commitFile: $!\n";
	my @lines=<F>;
	my $commitInfo = $lines[0];
	close F;
	return $commitInfo;
}

sub getLatestCommitOjbectBranchDir{
	my $lastCommitNumber = getLastCommitNumber();
	my $currentBranchName = getCurrentBranchName();
	if ($lastCommitNumber == -1){
		return '';
	}

	return "$objectDir$currentBranchName/$lastCommitNumber";
}

sub getLastCommitDotIndexFile{
	my $repoDir = getLatestCommitOjbectBranchDir();
	return "$repoDir/.index";
}

sub getFileListFromIndexFile{
	my $indexFile0 = @_>0?$_[0]:$indexFile;
	open F, '<', $indexFile0 or die "$0: Can't open $indexFile: $!\n";
	my @files = <F>;
	close F;
	return @files;
}

sub getLastCommitNumber{
	my $lastCommitInfo = getLastCommitInfo();
	my $commitNumber=-1;
	if ($lastCommitInfo =~ /^([0-9]+)/g ){
		$commitNumber = $1;
	}
	return $commitNumber;
}



sub getAddBufferObjDir{
	my $nextCommitNumber = getLastCommitNumber()+1;
	my $currentBranchName = getCurrentBranchName();
	my $objBufferFolder = "$objectDir$currentBranchName/$nextCommitNumber";
	unless (-e $objBufferFolder) {
		mkdir( $objBufferFolder ) or die "Unable to create $objBufferFolder folder, $!";
	}

	return $objBufferFolder;
}

sub getLastCommitObjDir{
	my $lastCommitNumber = getLastCommitNumber();
	if ($lastCommitNumber < 0){
		return "false";
	}
	my $currentBranchName = getCurrentBranchName();
	my $objLastCommitFolder = "$objectDir$currentBranchName/$lastCommitNumber";
	return $objLastCommitFolder;
}

sub getFileFromIndexBuffer{
	my $f = shift @_;
	my $addBufferObjDir = getAddBufferObjDir();
	if(-e "$addBufferObjDir/$f"){
		return "$addBufferObjDir/$f";
	}
	return 0;
}
sub getFilebeforeOrAtCommit{

	my $thisVersionFile = $_[0];
	my $lastCommitNumber = $_[1];
	my $currentBranchName = getCurrentBranchName();
	my $lastCommitFile = "";

	foreach my $i (sort {$a < $b } (0..$lastCommitNumber)){
		my $commitFile = "$objectDir$currentBranchName/$i/$thisVersionFile";
		my $dotIndex = "$objectDir$currentBranchName/$i/.index";
		if (-e $dotIndex ){
			#print "file $thisVersionFile, \$dotIndex:$dotIndex\n of commit $i which is before commit $lastCommitNumber";
			
			if (isFileInIndex($thisVersionFile,$dotIndex) ==0){
				return 0;
			}
		}
		if (-e "$commitFile"){
			return $commitFile;
		} 
	}
	return 0;
}

sub getFileLastestCommitNumber{

	my $thisVersionFile = $_[0];
	my $currentBranchName = getCurrentBranchName();
	my $lastCommitNumber = getLastCommitNumber();
	my $lastCommitFile = "";

	foreach my $i (sort {$a < $b } (0..$lastCommitNumber)){
		my $commitFile = "$objectDir$currentBranchName/$i/$thisVersionFile";
		if (-e "$commitFile"){
			return $i;
		} 
	}
	return -1;
}

#return 0 if file doesn't exist
sub getFileOfPreviousCommitVersion{
	my $thisVersionFile = $_[0];
	my $currentBranchName = getCurrentBranchName();
	my $lastCommitNumber = getLastCommitNumber();
	my $lastCommitFile = "";

	foreach my $i (sort {$a < $b } (0..$lastCommitNumber)){
		unless (-e "$objectDir$currentBranchName/$i/") {
			next;
		}
		my $dotIndexFile = "$objectDir$currentBranchName/$i/.index";
		unless (isFileInIndex($thisVersionFile,$dotIndexFile)){
			return 0;
		}
		my $commitFile = "$objectDir$currentBranchName/$i/$thisVersionFile";
		if (-e "$commitFile"){
			return $commitFile;
		} 
	}
	return 0;
}

#return 1 if files are not the same, 0 if file are same with previous commit
sub isSameAsPreviousCommit {
	my $thisVersionFile = $_[0];

	my $lastCommitFile = getFileOfPreviousCommitVersion($thisVersionFile);
	if ($lastCommitFile){
		my $result = compare ("$lastCommitFile","$thisVersionFile");
		return $result;
	}
	return 1; #not the same
}

sub catfile{
	my $file = $_[0];
	open F, '<', $file or die "$0: Can't open $file: $!\n";
	my @lines=<F>;
	close F;
	foreach my $line (@lines){
		print $line;
	}
}

#return 1 is file is in specified index file, 0 otherwise
sub isFileInIndex{
	my $file = $_[0];
	my $indexFile0 = @_>1?$_[1]:$indexFile;
	open F, '<', $indexFile0 or die "$0: Can't open $indexFile0: $!\n";
	my @lines = <F>;
	close F;

	foreach my $f (@lines){
		chomp($f);
		if ($f eq $file) {
			return 1;
		}
	}
	return 0;
}

#isFileInExactVersion($file,$commitNumber)
sub isFileInExactCommit{
	my $file = $_[0];
	my $commitNumber = $_[1];

	my $currentBranchName = getCurrentBranchName();
	my $lastCommitFile = "";

	my $commitFile = "$objectDir$currentBranchName/$commitNumber/$file";
	if (-e "$commitFile"){
		return $commitFile;
	} 
	return 0;
}

#==================== sub routines ======================
#./legit.pl init 
sub init{
	#test if the folder exists
	if (-e $legitDir){
		print "legit.pl: error: $legitDir already exists\n";

	}else{
		mkdir( $legitDir ) or die "Unable to create $legitDir folder, $!";
		print "Initialized empty legit repository in $legitDir\n";
	}
}

sub checkInit{
	unless (-e $legitDir){
		print "legit.pl: error: no .legit directory containing legit repository exists\n";
		exit 1;
	}
}

#Init all the stuff in .legit folder
sub initLegitRepo{
	#create an index file
	sysopen(F, $indexFile, O_CREAT  ) or die "Unable to create file $indexFile , $!";
	close F;

	#create a HEAD file to store the commmit and branch info 

	open F, '>>', $headFile or die "$0: Can't create $headFile: $!\n";
	print F "ref: refs/heads/master";
	close F;

	#create an object directory to store all the changes, both add buffer and commits
	mkdir( $objectDir ) or die "Unable to create $objectDir folder, $!";

	#create object/master to store files in the master
	mkdir( $objectMasterDir ) or die "Unable to create $objectMasterDir folder, $!";

	#create object/master/ to store index in the master
	mkdir( $objectMasterDir."/0" ) or die "Unable to create $objectMasterDir/0 folder, $!";

	#the refs
	mkdir( $refDir ) or die "Unable to create $refDir folder, $!";

	#funtionalized similar to .git/ref/head, store the branch info
	mkdir( $refHeadsDir ) or die "Unable to create $refHeadsDir folder, $!";

	#funtionalized similar to .git/ref/ref, store the commit info
	mkdir( $refTagDir ) or die "Unable to create $refTagDir folder, $!";
}

sub add{
	#checkInit();
	#check if the repository is initialized
	unless (-e $indexFile){
		initLegitRepo();
	}

	#get all the file from the command line arguments
	my @files = @_;
	
	#file validation: even if one of the files can't open, or contains illegal characters, don't add any files to index

	# if file is in the repo, should be successfully add.
	# how to submit deleted file?--solved
	# hash files, 1 means to need to update to IndexFIle, 0 otherwise
	#get Add buffer directory
	my $addBufferObjDir = getAddBufferObjDir();
	my %filesToAddToIndexFile;
	foreach my $f (@files){
		#i.file name illegal
		checkValidFileName($f);
		#ii. check if file occurs in index but not in local
		my $fInIndex = isFileInIndex($f);
		my $getLastCommitDotIndexFile = getLastCommitDotIndexFile();
		my $fInRepo = 0;
		if (-e $getLastCommitDotIndexFile){
			$fInRepo = isFileInIndex($f,getLastCommitDotIndexFile());
		}
		
		if (!(-e $f) and !$fInIndex and !$fInRepo) {
			print "legit.pl: error: can not open '$f'\n";
			exit 1;
		} elsif (!(-e $f) and $fInIndex and !$fInRepo){
			$filesToAddToIndexFile{$f}=1;
		} elsif (!(-e $f)) {
			$filesToAddToIndexFile{$f}=0;
		} else {
			$filesToAddToIndexFile{$f}=1;
		}
		if (isSameAsPreviousCommit($f) == 0 ){
			# for multiple add if same as previous commit
			# also need to remove this file from buffer
			if(-e "$addBufferObjDir/$f"){
				unlink "$addBufferObjDir/$f";
			}
			next;
		}
		if ($filesToAddToIndexFile{$f}==1 and -e $f and -e "$addBufferObjDir"){
	 		copy($f,"$addBufferObjDir")||warn "could not copy files :$!" ;
		}
	}

	#copy all the file to the add buffer dir

	# foreach my $f (@files){
	# 	if (exists $filesToAddToIndexFile{$f}){
	# 		if($filesToAddToIndexFile{$f} eq "0"){
	# 			next;
	# 		}
	# 	}

	# 	#if add file is the same as last commit, don't put it in the index.
	# 	if (isSameAsPreviousCommit($f) == 0 ){
	# 		# for multiple add if same as previous commit
	# 		# also need to remove this file from buffer
	# 		if(-e "$addBufferObjDir/$f"){
	# 			unlink "$addBufferObjDir/$f";
	# 		}
	# 		next;
	# 	}

	# }

	#add filename to index.
	#my @idxfiles = glob("$addBufferObjDir/*");
	open F, '<', $indexFile or die "$0: Can't open $indexFile: $!\n";
	my @lines = <F>;
	close F;

	foreach my $f (@lines){
		chomp($f);
		if (!exists($filesToAddToIndexFile{$f}) && $f ne "") {
			$filesToAddToIndexFile{$f} = 1;
		}
	}


	open F, '>', $indexFile or die "$0: Can't open $indexFile: $!\n";
	foreach my $f (sort keys %filesToAddToIndexFile){
		if ($filesToAddToIndexFile{$f} ){
			print F "$f\n";
		}
	}
	close F;

	copy($indexFile, "$addBufferObjDir/.index")||warn "could not copy $indexFile :$!" ;
	
}


sub commit{
	#if no file in index, return
	open F, '<', $indexFile or die "$0: Can't open $indexFile: $!\n";
	my @indexLines=<F>;
	close F;
	my $dotIndexFile = getLastCommitDotIndexFile();
	if(@indexLines == 0 and !(-e $dotIndexFile)){
		print "nothing to commit\n";
		exit 1;
	}

	unless (-e $dotIndexFile and compare($indexFile, $dotIndexFile)!=0){
		my @filesToCommit = ();
		foreach my $f (@indexLines){
			chomp($f);
			unless (isSameAsPreviousCommit($f) == 0){
				if(-e $f ){
					push @filesToCommit,$f;
				}
			}
		}
	
		if(@filesToCommit == 0){
			print "nothing to commit\n";
			exit 1;
		}
	}
	my $cmmt_msg = $_[0];

	#get current branch name
	my $currentBranchName = getCurrentBranchName();
	my $lastCommitNumber = getLastCommitNumber();
	my $thisCommitNumber = $lastCommitNumber+1;
	my $tagBranch = getCurrentBranchTag();

	my $commitFile = getLastCommitFile();
	
	unless (-e $tagBranch){
		mkdir($tagBranch) or die "Unable to create $tagBranch folder, $!";
	}

	if (-e $commitFile) {
		copy($commitFile,"$tagBranch$currentBranchName") || warn "could not copy files :$commitFile" ;
		rename "$tagBranch/$currentBranchName","$tagBranch/$lastCommitNumber"
	}
	open F, '>', $commitFile or die "$0: Can't open $commitFile: $!\n";
	my $content = "$thisCommitNumber $cmmt_msg";
	print F $content;
	close F;
	print "Committed as commit $thisCommitNumber\n";
}

# all files already in the index to have their contents from the current directory 
# added to the index before the commit
sub commit_a{
	my $cmmt_msg = $_[0];
	#find files already in the index <files> (from add buffer dir)
	my $addBufferObjDir = getAddBufferObjDir();
	my @indexFilesPath = glob("$addBufferObjDir/*");
	my @indexFilesName;
	my @filesToAddAgain;

	open F, '<', $indexFile or die "$0: Can't open $indexFile: $!\n";
	my @lines = <F>;
	close F;

	foreach my $f (@lines){
		chomp($f);
		push @filesToAddAgain,$f;

	}
	add(@filesToAddAgain);
	commit($cmmt_msg);

}

sub getlog{
	my $lastCommitNumber = getLastCommitNumber();
	my $lastCommitFile = getLastCommitFile();
	unless (-e $lastCommitFile) {
		# if no commits: legit.pl: error: your repository does not have any commits yet
		print "legit.pl: error: your repository does not have any commits yet\n";
		exit 1;
	}
	open F, '<', $lastCommitFile or die "$0: Can't create $lastCommitFile: $!\n";
	my @linesLast=<F>;
	print $linesLast[0]."\n";
	close F;

	my $tagBranch = getCurrentBranchTag(); 
	foreach my $i (sort {$a < $b } (0..($lastCommitNumber-1))){
		open F, '<', "$tagBranch/$i" or die "$0: Can't create $tagBranch/$i: $!\n";
		my @lines=<F>;
		print $lines[0]."\n";
		close F;
	}
}

#legit.pl show commit:filename
sub show{
	my $commitNumber="";
	my $commitFile; 
	my $currentBranchName = getCurrentBranchName();
	my $indexFlag = 0;
	my $lastestCommitNumber = getLastCommitNumber();

	if($_[0] =~ /^([0-9]*):(.*)/g){
		($commitNumber,$commitFile)=($1,$2);
	}else{
		print "legit.pl: error: invalid object $_[0]\n";
		exit 1;
	}
	


	if ($commitNumber eq ""){
		$commitNumber=getLastCommitNumber()+1;
		$indexFlag = 1;
	} 
		#my $dotIndex = "$objectDir$currentBranchName/$commitNumber/.index";

		my $dotIndex = $indexFlag?$indexFile:"$objectDir$currentBranchName/$commitNumber/.index";
		unless (-e $dotIndex) {
			print "legit.pl: error: unknown commit '$commitNumber'\n";
			exit 1;
		}
		elsif (isFileInIndex($commitFile,$dotIndex) ==0){
			my $errMsg = $indexFlag?"legit.pl: error: '$commitFile' not found in index\n":"legit.pl: error: '$commitFile' not found in commit $commitNumber\n";
			print $errMsg;
			exit 1;
		}
	


	my $file = getFilebeforeOrAtCommit($commitFile,$commitNumber);
	

	unless (-e $file) {
		my $errMsg = $indexFlag?"legit.pl: error: '$commitFile' not found in index\n":"legit.pl: error: '$commitFile' not found in commit $commitNumber\n";
		print $errMsg;
	}


	# my $isFileInIndexFlag = isFileInIndex($commitFile);

	# if ($commitNumber eq "" and $isFileInIndexFlag eq "0"){
	# 	print ("legit.pl: error: '$commitFile' not found in index\n");
	# 	exit 1;
	# } elsif ($isFileInIndexFlag eq "0"){
	# 	my $lastestCommitNumber = getFileLastestCommitNumber($commitFile);
	# 	if ($lastestCommitNumber == -1 ){
	# 		print ("legit.pl: error: '$commitFile' not found in commit $commitNumber\n");
	# 		exit 1;
	# 	} 

	# }elsif ($commitNumber eq ""){
	# 	$commitNumber=getLastCommitNumber()+1;
	# 	$indexFlag = 1;
	# }

	# my $fileDir = "$objectDir$currentBranchName/$commitNumber";

	# unless (-e $fileDir || $indexFlag) {
	# 	print ("legit.pl: error: unknown commit '$commitNumber'\n");
	# 	exit 1;
	# }

	# my $file = "$fileDir/$commitFile";
	# unless (-e $file) {
	# 	$file = getFilebeforeOrAtCommit($commitFile,$commitNumber);
	# }
	# unless (-e $file) {
	# 	if ($indexFlag){
	# 		print ("legit.pl: error: '$commitFile' not found in index\n");	
	# 	}else{
	# 		print ("legit.pl: error: '$commitFile' not found in commit $commitNumber\n");
	# 	}
	# 	exit 1;
	# }
	catfile($file);
}

sub check_valid_rm{
	my $forceFlag = shift @_;
	my $cachedFlag = shift @_;
	my $rmFile =  shift @_;
	my $r = getFileStatus($rmFile);
	if ($forceFlag  and ($r==6) ) {
		return;
	}elsif ($forceFlag  and $cachedFlag and ($r==0)) {
		return 0;
	}
	elsif ($cachedFlag and ($r == 63 or $r = 22 or $r == 15 or $r == 23 )) {
		return 0;
	}
	elsif ($r == 15) {
		print "legit.pl: error: '$rmFile' in repository is different to working file\n";
		exit 1;
	}
	elsif ( $r == 22){
		print "legit.pl: error: '$rmFile' is not in the legit repository\n";
		#print $r."\n";
		exit 1;
	} elsif ($r ==7 ){
		print "legit.pl: error: '$rmFile' in index is different to both working file and repository\n";
		exit 1;
	} elsif ($r == 63){
		return 0;
	} elsif ( $r == 23){
		print "legit.pl: error: '$rmFile' has changes staged in the index\n";
		exit 1;
	} elsif ($r == 12){
		print "legit.pl: error: '$rmFile' has changes staged in the index\n";
	}
	else{
		return 0;
	}

}
sub rm{
	#rm($options{"--force"},$options{"--cached"},@rmFiles);
	my $forceFlag = shift @_;
	my $cachedFlag = shift @_;
	my @rmFiles =  @_;
	my %newIndexFiles;
	foreach my $rmFile (@rmFiles) {
		check_valid_rm($forceFlag ,$cachedFlag,$rmFile);
		$newIndexFiles{$rmFile}=0;
	}

	# file remove from current dir
	unless ($cachedFlag) {
		foreach my $rmFile (@rmFiles) {
			unlink($rmFile);
		}
	}

	#file remove from index
	foreach my $rmFile (@rmFiles) {
		my $indexVersion =  getFileFromIndexBuffer($rmFile);
		if ($indexVersion ne "0"){
			unlink($indexVersion);
		}
	}

	open F, '<', $indexFile or die "couldn't open index file.";
	my @indexFiles = <F>;
	close F;

	foreach my $f (@indexFiles){
		chomp $f;
		unless (exists ($newIndexFiles{$f}) ){
			$newIndexFiles{$f}=1;
		}
	}
	open F, '>',  $indexFile or die "couldn't open index file.";
	foreach my $file (sort keys %newIndexFiles){
		if ($newIndexFiles{$file}){
			print F $file."\n";
		}
	}
	close F;
	my $addBufferObjDir = getAddBufferObjDir();
	copy($indexFile, "$addBufferObjDir/.index")||warn "could not copy $indexFile :$!" ;
	
}

sub status{
	#(show) status of the file, in alphabetic order
	#if no commits:legit.pl: error: your repository does not have any commits yet

	#1. fetch all file and get existance status
	#mark the file existance bit by bit
	#file in local: 0b100, 4
	#file in index: 0b010, 2
	#file in repo:  0b001, 1
=pod
(0 means file doesn't exists, 1 means file exists)
	local 	index 	repo	bit_or（decimal）desc
	    1	    0	   0	     4			untracked
	    0	    1	   1	     3			file deleted
	  0/1	    0	   1	   1/5			deleted
	  0/1	    1	   0	   2/6			added to index
	    1	    1	   1	     7			need more option

=cut
	my %files;

	#1.1 fetch file from local
	foreach my $f (glob("*")){
		unless (exists $files{$f}) {
			$files{$f} = 4;
		}else {
			$files{$f} = $files{$f} | 4;
		}
	}

	#1.2 fetch file from index,$my indexFile

	open F, '<', $indexFile or die "$0: Can't open $indexFile: $!\n";
	my @indexFiles = <F>;
	close F;

	foreach my $f (@indexFiles){
		chomp($f);
		unless (exists $files{$f}) {
			$files{$f} = 2;
		} else {
			$files{$f} = $files{$f} | 2;
		}
	}

	#1.3 fetch file from repo, getFileOfPreviousCommitVersion($file)
	my $lastCommitNumber = getLastCommitNumber();
	my $currentBranchName = getCurrentBranchName();
	
	#only need to read the lasted .index file in the commit repo and get all the filenames
	foreach my $i (0..$lastCommitNumber){
		my $repoDir = "$objectDir$currentBranchName/$i/";
		my @repoFiles = glob("$repoDir*");
		foreach my $f (@repoFiles) {
			if($f =~/$repoDir(.+)/g){
				my $fileWithoutPath = $1;
				unless (exists $files{$fileWithoutPath}) {
					$files{$fileWithoutPath} = 1;
				} else{
					$files{$fileWithoutPath} = $files{$fileWithoutPath} | 1;
				}
			}
		}
	}


	foreach my $f (keys %files){
		if ($files{$f} == 7){
			my $equalStatus = getFileDiffStatus($f);
			$files{$f} = $equalStatus <<3 | 7;
		}
	}
=pod
	foreach my $f (keys %files){
		print "$f : $files{$f} ";
		my $r = $files{$f} & 2;
		if (($files{$f} & 2) == 0){
			print "catched!";
		}
		print ", $files{$f} & 2 is $r\n";

	}
=cut

	foreach my $f (sort keys %files){
		# if (($files{$f} & 2) == 0){
		# 	print "$f - untracked\n";
		# } els
		if ($files{$f} == 4){
			print "$f - untracked\n";
		} elsif ($files{$f} == 3){
			print "$f - file deleted\n";
		} elsif ($files{$f} == 1 or $files{$f} == 5 ){
			print "$f - deleted\n";
		} elsif ($files{$f} == 2 or $files{$f} == 6 ){
			print "$f - added to index\n";
		} elsif ($files{$f} == 7){
			print "$f - file changed, different changes staged for commit\n";
		} elsif ($files{$f} == 15){
			print "$f - file changed, changes not staged for commit\n";
		} elsif ($files{$f} == 23){
			print "$f - file changed, changes staged for commit\n";
		} elsif ($files{$f} == 31){
			print "$f - same as repo\n";
		} 
	}
}

sub getFileDiffStatus{
=pod
for each file that bit or result is 7, means this file exists in index, local and repo.
we now need to compare the difference of each file.
(1 means two files are equal, 0 means two files are Different)
local==index 	index==repo		bit_or		bit_or<<3 | 7	desc
		   0			  0     0     					 7	a,file changed, different changes staged for commit
		   0			  1     1     					15	c,file changed, changes not staged for commit
		   1			  0     2     					23	b,file changed, different changes staged for commit
		   1			  1     3     					31	f,same as repo

=cut
	my $localFile = $_[0];
	my $indexFile = getFileFromIndexBuffer($localFile);
	my $repoFile = getFileOfPreviousCommitVersion($localFile);
	
	my $indexDiffLocal = compare($indexFile,$localFile) == 0 ? 1:0;
	my $indexDiffRepo = compare($indexFile,$repoFile) == 0 ? 1:0;
	my $localDiffRepo = compare($localFile,$repoFile) == 0 ? 1:0;
	if ($indexFile eq "0"){
		$indexDiffLocal = $localDiffRepo;
		$indexDiffRepo = 1;
	}
	my $result = $indexDiffLocal<<1 | $indexDiffRepo;
=pod
	print "filename:$localFile:\n";
	print "$localFile,$indexFile,$repoFile, result: $result\n";
	print "\$indexDiffLocal:$indexDiffLocal,\$indexDiffRepo:$indexDiffRepo, \$localDiffRepo: $localDiffRepo";
	print "\n=========\n";
=cut
	return $indexDiffLocal<<1 | $indexDiffRepo ;
}

#legit.pl branch [-d] [branch-name]
sub branchCreate{
	my $branchName = $_[0];
	#if branch exists?
	if (-e "$refDir/heads/$branchName"){
		print "legit.pl: error: branch '$branchName' already exists";
		exit 1;
	}
	my $addBufferObjDir = getAddBufferObjDir();
	if (-e $indexFile) {
		copy($indexFile, "$addBufferObjDir/.index")||warn "could not copy $indexFile :$!" ;
	}

	open F, '>', $indexFile or die "couldn't open index file.";
	close F;

	open F, '>', $headFile or die "$0: Can't create $headFile: $!\n";
	print F "ref: refs/heads/$branchName";
	close F;

	mkdir( "$objectDir/$branchName" ) or die "Unable to create $objectDir/$branchName folder, $!";
	#create object/br/ to store index in the branch
	mkdir( "$objectDir/$branchName/0" ) or die "Unable to create $objectDir/$branchName/0 folder, $!";
}

sub branchDelete{

}

sub branchList{
	my $branchRef = getCurrentBranchRef();
	my @branches = sort glob("$refDir/heads/*");
	foreach $b (@branches ) {
		if ($b =~/legit\/ref\/heads\/(.*)/g){
			print $1."\n";
		}
	}

}

#legit.pl checkout branch-name
sub checkout{
}

#merge branch-name|commit
sub merge{
	#can
}

sub challenge{
	#use  pointer to compare  file, if 
}


#only for test purpose
sub printStatusBitOr{

=pod   5 bit-or 
(0 means file doesn't exists or file not same , 1 means file exists or file same,)
local==index	index==repo	in_local	in_index	in_repo	bit-or
0	0	0	0	0	0
0	0	0	0	1	1
0	0	0	1	0	2
0	0	0	1	1	3
0	0	1	0	0	4
0	0	1	0	1	5
0	0	1	1	0	6
		1	1	1	7
0	1	0	0	0	8
0	1	0	0	1	9
0	1	0	1	0	10
0	1	0	1	1	11
0	1	1	0	0	12
0	1	1	0	1	13
0	1	1	1	0	14
0	1	1	1	1	15
1	0	0	0	0	16
1	0	0	0	1	17
1	0	0	1	0	18
1	0	0	1	1	19
1	0	1	0	0	20
1	0	1	0	1	21
1	0	1	1	0	22
1		1	1	1	23
1	1	0	0	0	24
1	1	0	0	1	25
1	1	0	1	0	26
1	1	0	1	1	27
1	1	1	0	0	28
1	1	1	0	1	29
1	1	1	1	0	30
1	1	1	1	1	31
local==index	index==repo	in_local	in_index	in_repo	bit-or
=cut

=pod
sub indexOfList{
	my $flag = shift @_;
	my @list = @_;
	foreach $i (0..@_){
		return $i if $@_[$i] eq $flag;
	}
	return 0;
}
=cut

	my %fileBit;

	my $indexDir = getAddBufferObjDir();	#for compare purpose
	my $repoDir = getLatestCommitOjbectBranchDir();	#for compare purpose
	my @localFiles = glob("*");
	my @indexFilesAll = getFileListFromIndexFile();
	my @repoFiles = getFileListFromIndexFile("$repoDir/.index");
	# print "local:";
	# print @localFiles;
	# print "\nindex:";
	# print @indexFilesAll;
	# print "\nrepo:";
	# print @repoFiles;
	foreach my $f (@localFiles){
			chomp($f);
		$fileBit{$f} = (exists $fileBit{$f})? ($fileBit{$f} | 4):4;
	}
	foreach my $f (@indexFilesAll){
			chomp($f);
		$fileBit{$f} = (exists $fileBit{$f})? ($fileBit{$f} | 2):2;
	}
	foreach my $f (@repoFiles){
			chomp($f);
		$fileBit{$f} = (exists $fileBit{$f})? ($fileBit{$f} | 1):1;
	}
	
	#local==index 16
	#index==repo 8
	#localEqRepo = 32
# 32				16			8				4			2			1			
#local==repo local==index	index==repo		in_local	in_index	in_repo		bit-or
#	
	my $lastestCommitNumber = getLastCommitNumber();

	foreach my $f (keys %fileBit){
		#my $localEqIndex = 1;
		#$f is local

	# my $repoVersion = getFileOfPreviousCommitVersion($rmFile);
	# my $indexVersion = getFileFromIndexBuffer($rmFile);
		my $repoF = getFilebeforeOrAtCommit($f,$lastestCommitNumber);
		my $indexF = getFilebeforeOrAtCommit($f,$lastestCommitNumber+1);
		
		my $localEqRepo = 0;
		my $localEqIndex = 0;
		my $indexEqRepo = 0;
		my $inLocal = $fileBit{$f} & 4;
		my $inRepo = $fileBit{$f} & 2;
		my $inIndex = $fileBit{$f} & 1;
=pod		print "($f,$repoF,$indexF)\n";

		if($f eq "a1" or $f eq 'a2'){
			print ("index of $f is:\n");
			show (":$f");
			print ("commit $lastestCommitNumber of $f is:\n");
			show ("$lastestCommitNumber:$f");

		}
=cut
		if (($inLocal | $inRepo ) == 0 or compare("$f","$repoF") == 0){
			$localEqRepo = $localEqRepo | 32;
		}
		if (($inLocal | $inIndex ) == 0 or compare("$f","$indexF")==0){
			$localEqIndex = $localEqIndex | 16;
		}
		if (($inRepo | $inIndex ) == 0 or compare("$repoF","$indexF")==0){
			$localEqIndex = $localEqIndex  | 8;
		}

		$fileBit{$f} = $fileBit{$f} | $localEqRepo | $localEqIndex | $indexEqRepo;


	}

	# foreach  my $f(sort keys %fileBit){
	# 	my $exist = $fileBit{$f} & 7;
	# 	my $equal = $fileBit{$f} & (32+16+8);

	# 	my $equalshift = ($fileBit{$f} & 56)>>3;
	# 	#print "$f - $equal - $exist - $fileBit{$f} "."$equal>>3: $equalshift\n"; 
	# 	print "$f - $fileBit{$f} \n";
	# }

	#based on testAL.sh result
	foreach my $f (sort keys %fileBit){
		my $r = $fileBit{$f};
		if($r == 0 or $r == 18){
			next;
		}elsif ($r == 3 or $r == 22){
			print "$f - added to index\n";
		}elsif ($r == 5 or $r == 37 or $r == 12){
			print "$f - untracked\n";
		}elsif ($r == 7){
			print "$f - file changed, different changes staged for commit\n";
		}elsif ($r == 11){
			print "$f - file deleted\n";
		}elsif ($r == 15){
			print "$f - file changed, changes not staged for commit\n";
		}elsif ($r == 23){
			print "$f - file changed, changes staged for commit\n";
		}elsif ($r == 33){
			print "$f - deleted\n";
		}elsif ($r == 63){
			print "$f - same as repo\n";
		}else{
			next;
		}
	}
=pod
the test result are
0	not show
1	
2	
3	added to index
4	
5	untracked
6	
7	file modified and changes in index
...	
11	file deleted
12	untracked
13	
14	
15	changes in index
..	
18	not show
...
22	added to index
23	file modified
...
bit-or	
	
33	deleted
37	untracked

63	same as repo
=cut
}

sub getFileStatus{
	my $f = $_[0];
	my $bit = 0;
	my $indexDir = getAddBufferObjDir();	#for compare purpose
	my $repoDir = getLatestCommitOjbectBranchDir();	#for compare purpose
	my @localFiles = glob("*");
	my @indexFilesAll = getFileListFromIndexFile();
	my @repoFiles = getFileListFromIndexFile("$repoDir/.index");

	if( indexOfList($f,@localFiles) >= 0) {
		$bit = $bit | 4;
	}

	foreach my $file (@indexFilesAll){
		chomp($file);
		if ($f eq $file){
			$bit = $bit | 2;
			last;
		}
	}
	foreach my $file (@repoFiles){
		chomp($file);
		if ($f eq $file){
			$bit = $bit | 1;
			last;
		}
	}
	
	#local==index 16
	#index==repo 8
	#localEqRepo = 32
# 32				16			8				4			2			1			
#local==repo local==index	index==repo		in_local	in_index	in_repo		bit-or
#	
	my $lastestCommitNumber = getLastCommitNumber();
	my $repoF = getFilebeforeOrAtCommit($f,$lastestCommitNumber);
	my $indexF = getFilebeforeOrAtCommit($f,$lastestCommitNumber+1);
	
	my $localEqRepo = 0;
	my $localEqIndex = 0;
	my $indexEqRepo = 0;
	my $inLocal = $bit & 4;
	my $inRepo = $bit & 2;
	my $inIndex = $bit& 1;

	if (($inLocal | $inRepo ) == 0 or compare("$f","$repoF") == 0){
		$localEqRepo = $localEqRepo | 32;
	}
	if (($inLocal | $inIndex ) == 0 or compare("$f","$indexF")==0){
		$localEqIndex = $localEqIndex | 16;
	}
	if (($inRepo | $inIndex ) == 0 or compare("$repoF","$indexF")==0){
		$localEqIndex = $localEqIndex  | 8;
	}

	$bit = $bit| $localEqRepo | $localEqIndex | $indexEqRepo;

	return $bit;

}

