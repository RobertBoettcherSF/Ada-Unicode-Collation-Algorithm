.PHONY: all test clean

OBJ_DIR = obj
BIN_DIR = bin
GPR_FILE = unicode_collation.gpr
MAIN_EXE = $(BIN_DIR)/unicode_collation
TEST_EXE = $(BIN_DIR)/tests

all: $(MAIN_EXE) $(TEST_EXE)

$(MAIN_EXE): main.adb unicode_collation.ads unicode_collation.adb
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gnatmake -P $(GPR_FILE) -o $(MAIN_EXE) main.adb

$(TEST_EXE): tests.adb unicode_collation.ads unicode_collation.adb
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)
	gnatmake -P $(GPR_FILE) -o $(TEST_EXE) tests.adb

test: $(TEST_EXE)
	@echo "Running Unicode Collation Algorithm tests..."
	@$(TEST_EXE)

clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

.PHONY: all test clean
