########################################################################
####################### Makefile Template ##############################
########################################################################

# Compiler settings - Can be customized.  -Wall -Wextra -Wshadow -pedantic
CC = gfortran
CPP = gfortran -cpp
CXXFLAGS = -g -O0 -ffree-line-length-none -cpp
LDFLAGS = 

# Makefile settings - Can be customized.
APPNAME = a.out
EXT = .f90
SRCDIR = src
OBJDIR = obj

############## Do not change anything from here downwards! #############
SRC = $(wildcard $(SRCDIR)/*$(EXT))
OBJ = $(SRC:$(SRCDIR)/%$(EXT)=$(OBJDIR)/%.o)
DEP = $(OBJ:$(OBJDIR)/%.o=%.d)
# UNIX-based OS variables & settings
RM = rm
DELOBJ = $(OBJ)

########################################################################
####################### Targets beginning here #########################
########################################################################

all: makeObjDir $(APPNAME)

# Makes and cleans project
.PHONY: makeAndClean
makeNotClean: makeObjDir $(APPNAME) clean

# Makes dir for object files
makeObjDir:
	[ -d $(OBJDIR) ] || mkdir $(OBJDIR)

# Builds the app
$(APPNAME): $(OBJ)
	$(CC) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# Creates the dependecy rules
%.d: $(SRCDIR)/%$(EXT)
	@$(CPP) $(CFLAGS) $< -MM -MT $(@:%.d=$(OBJDIR)/%.o) >$@

# Includes all .h files
-include $(DEP)

# Building rule for .o files and its .c/.cpp in combination with all .h
$(OBJDIR)/%.o: $(SRCDIR)/%$(EXT)
	$(CC) $(CXXFLAGS) -o $@ -c $<

################### Cleaning rules for Unix-based OS ###################
# Cleans complete project
.PHONY: cleanWithApp
cleanWithApp: clean
	$(RM) -f $(APPNAME)

# Cleans project except app
.PHONY: clean
clean:
	$(RM) -f $(DEP) $(DELOBJ)
	$(RM) -fr $(OBJDIR)
