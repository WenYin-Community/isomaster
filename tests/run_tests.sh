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
