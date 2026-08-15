#!/bin/bash
# ============================================================================
# run_tests.sh - bkisofs 单元测试运行脚本
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================"
echo "  bkisofs 单元测试运行器"
echo "========================================"
echo ""

# 检查 bk 库是否存在
if [ ! -f "../bk/bk.a" ]; then
    echo -e "${YELLOW}警告: bk.a 不存在，正在编译...${NC}"
    make -C ../bk
fi

# 编译测试
echo -e "${YELLOW}步骤 1: 编译测试程序...${NC}"
make clean
make all

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 编译失败${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2: 运行测试...${NC}"
echo ""

# 运行测试
./test_bk
TEST_RESULT=$?

echo ""
echo -e "${YELLOW}步骤 2b: Vala 后台线程回归测试...${NC}"
echo ""

VALA_RESULT=0
if command -v valac >/dev/null 2>&1; then
    valac --pkg glib-2.0 -o test_iso_ops test_iso_operations.vala ../iso-operations.vala 2>/dev/null
    ./test_iso_ops
    VALA_RESULT=$?
    rm -f test_iso_ops test_iso_operations.vala.c ../iso-operations.vala.c
    if [ $VALA_RESULT -ne 0 ]; then
        echo -e "${RED}错误: Vala 后台线程回归测试失败${NC}"
        exit 1
    fi
else
    echo "SKIP: valac 不可用，跳过 Vala 回归测试"
fi

echo ""
echo -e "${YELLOW}步骤 2c: owned-delegate 转移静态检查...${NC}"
echo ""

if [ -f ../isomaster.c ]; then
    ./check_owned_transfer.sh
else
    echo "SKIP: isomaster.c 不存在（需先 make -f Makefile.vala）"
fi

echo ""

# 清理临时文件
echo -e "${YELLOW}步骤 3: 清理临时文件...${NC}"
rm -f /tmp/test_bk_*.iso /tmp/test_bk_*.txt 2>/dev/null || true
rm -rf /tmp/test_bk_extract_dir 2>/dev/null || true

if [ $TEST_RESULT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  所有测试通过!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  部分测试失败!${NC}"
    echo -e "${RED}========================================${NC}"
fi

exit $TEST_RESULT
