#!/usr/bin/bash
# Script for transfering source files to remote host,
# compiling and running

# T - launching on virtual Ubuntu
# F - launching on IPM cluster
ISLOCAL=T

# working dir with Makefile and src folder
WORKINGDIR=LW3_Pi_Monte_Carlo

# login information
if [[ $ISLOCAL = "T" ]]; then
    USERNAME=vladimir
    HOSTNAME=vm-ubuntu
else
    USERNAME=studentmpi
    HOSTNAME=greywizard
fi

# temp dir which will be created on remote host
if [[ $ISLOCAL = "T" ]]; then
    TARGETDIR=/tmp/EVV
else
    TARGETDIR=~/work/Evdokimov
fi
# makefile for compiling on remote host
MAKEFILE=Makefile
# name of compiled file according to makefile
COMPILEDFILE=a.out

# mpirun or srun
if [[ $ISLOCAL = "T" ]]; then
    MPIRUNNER=mpirun
    MPIRUNNER_ARGS="-n 4"
else
    MPIRUNNER=srun
    MPIRUNNER_ARGS="-n 16 -p hobbits"
fi

# ==============================================================
# removing temp dir if exists
ssh $USERNAME@$HOSTNAME "\[ -d $TARGETDIR \] && rm -fr $TARGETDIR"

# creatng temp dir
ssh $USERNAME@$HOSTNAME mkdir $TARGETDIR

# sending source files and Makefile
scp -r $WORKINGDIR/. $USERNAME@$HOSTNAME:$TARGETDIR

# compiling and running files, deleting temp dir
ssh $USERNAME@$HOSTNAME "cd $TARGETDIR; make; $MPIRUNNER $MPIRUNNER_ARGS ./$COMPILEDFILE"

# removing temp dir
ssh $USERNAME@$HOSTNAME "rm -rf $TARGETDIR"