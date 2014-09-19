BIN_DIR = bin/
EXE_NAME = lappyLogger

all: *.m
	mkdir -p $(BIN_DIR)
	clang -fobjc-arc -framework Foundation *.m -o $(BIN_DIR)$(EXE_NAME)
