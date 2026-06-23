# Makefile for bkisofs unit tests

CC = gcc
CFLAGS = -Wall -pedantic -std=gnu99 -Wno-unused-parameter -g
CPPFLAGS = -D_FILE_OFFSET_BITS=64

# bk 库路径
BK_DIR = ../bk
BK_LIB = $(BK_DIR)/bk.a

# 测试源文件
TEST_SRC = test_bk.c
TEST_BIN = test_bk

.PHONY: all clean test

all: $(TEST_BIN)

$(TEST_BIN): $(TEST_SRC) $(BK_LIB)
	@echo "编译测试程序..."
	$(CC) $(CFLAGS) $(CPPFLAGS) -I$(BK_DIR) $(TEST_SRC) $(BK_LIB) -o $@
	@echo "编译完成: $(TEST_BIN)"

$(BK_LIB):
	@echo "编译 bk 库..."
	$(MAKE) -C $(BK_DIR)

test: $(TEST_BIN)
	@echo "运行测试..."
	./$(TEST_BIN)

clean:
	@echo "清理测试文件..."
	$(RM) $(TEST_BIN)
	$(RM) /tmp/test_bk_*.iso /tmp/test_bk_*.txt 2>/dev/null || true
