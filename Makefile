BIN_DIR = bin/
EXE_NAME = lappyLogger

all: *.m
	mkdir -p $(BIN_DIR)
	clang -framework Foundation *.m -o $(BIN_DIR)$(EXE_NAME)
