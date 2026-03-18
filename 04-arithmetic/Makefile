SRC     = program.s
OBJ     = $(SRC:.s=.o)
BIN     = $(SRC:.s=)
SYSROOT = $(shell xcrun --sdk macosx --show-sdk-path)
LDFLAGS = -arch arm64 -lSystem -syslibroot $(SYSROOT) -e _start

all: $(BIN)

$(OBJ): $(SRC)
	as -arch arm64 -o $@ $<

$(BIN): $(OBJ)
	ld $(LDFLAGS) -o $@ $<

run: $(BIN)
	./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)

.PHONY: all run clean
