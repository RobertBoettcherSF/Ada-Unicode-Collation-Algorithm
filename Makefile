# Makefile for Unicode Collation Algorithm

.PHONY: all test clean

# Compiler
GNAT = gnatmake

# Directories
OBJ_DIR = obj
BIN_DIR = bin
SRC_DIR = .

# Files
ADS_FILES = $(wildcard *.ads)
ADB_FILES = $(wildcard *.adb)
GPR_FILE = unicode_collation.gpr

# Executables
MAIN_EXE = $(BIN_DIR)/unicode_collation
TEST_EXE = $(BIN_DIR)/tests

all: $(MAIN_EXE) $(TEST_EXE)

$(MAIN_EXE): main.adb $(ADS_FILES) $(ADB_FILES)
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE) -o $(MAIN_EXE) main.adb

$(TEST_EXE): tests.adb $(ADS_FILES) $(ADB_FILES)
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -P $(GPR_FILE) -o $(TEST_EXE) tests.adb

test: $(TEST_EXE)
	@echo "Running Unicode Collation Algorithm tests..."
	@$(TEST_EXE)

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

# Phony targets
.PHONY: all test clean
