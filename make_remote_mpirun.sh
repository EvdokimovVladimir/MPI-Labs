#!/usr/bin/bash
# Script for transfering source files to remote host,
# compiling and running
# -l — on local machine
# -v — on virtual machine
# -c — on cluster

# working dir with Makefile and src folder
WORKINGDIR=LW5_SLAE_Jacoby

# login information
case "$1" in
-v) 
    USERNAME=vladimir
    HOSTNAME=vm-ubuntu.local ;;
-c) 
    USERNAME=studentmpi
    HOSTNAME=greywizard ;;
esac


# temp dir which will be created on remote host
case "$1" in
-v) 
    TARGETDIR="/tmp/EVV" ;;
-c) 
    TARGETDIR="~/work/Evdokimov" ;;
esac

# makefile for compiling on remote host
MAKEFILE=Makefile
# name of compiled file according to makefile
COMPILEDFILE=a.out

# mpirun or srun

if [ "$1" = "-c" ] 
then 
    MPIRUNNER=srun
    MPIRUNNER_ARGS="-n 4 -p hobbits"
else
    MPIRUNNER=mpirun
    MPIRUNNER_ARGS="-n 4"
fi

# ==============================================================
if [[ ("$1" = "-v") || ("$1" = "-c")]]
then 
    # removing temp dir if exists
    ssh $USERNAME@$HOSTNAME "\[ -d $TARGETDIR \] && rm -fr $TARGETDIR"

    # creatng temp dir
    ssh $USERNAME@$HOSTNAME mkdir $TARGETDIR

    # sending source files and Makefile
    scp -r $WORKINGDIR/. $USERNAME@$HOSTNAME:$TARGETDIR
fi

if [[ ("$1" = "-l") || ("$1" = "")]]
then 
    # changing dir
    cd $WORKINGDIR

    # compiling
    make

    # running
    $MPIRUNNER $MPIRUNNER_ARGS ./$COMPILEDFILE
else
    # compiling and running files, deleting temp dir
    ssh $USERNAME@$HOSTNAME "cd $TARGETDIR; make; $MPIRUNNER $MPIRUNNER_ARGS ./$COMPILEDFILE"

    # removing temp dir
    ssh $USERNAME@$HOSTNAME "rm -rf $TARGETDIR"
fi