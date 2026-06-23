/******************************* LICENCE **************************************
* Any code in this file may be redistributed or modified under the terms of
* the GNU General Public Licence as published by the Free Software
* Foundation; version 2 of the licence.
****************************** END LICENCE ***********************************/

/******************************************************************************
* test_bk.c
* Unit tests for bkisofs library
******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>

#include "../bk/bk.h"

/* 测试计数器 */
static int tests_run = 0;
static int tests_passed = 0;
static int tests_failed = 0;

/* 测试宏 */
#define TEST_START(name) do { \
    printf("  [TEST] %-50s ", name); \
    fflush(stdout); \
    tests_run++; \
} while(0)

#define TEST_PASS() do { \
    printf("✓ PASS\n"); \
    tests_passed++; \
} while(0)

#define TEST_FAIL(msg) do { \
    printf("✗ FAIL: %s\n", msg); \
    tests_failed++; \
} while(0)

#define ASSERT_TRUE(cond, msg) do { \
    if (!(cond)) { TEST_FAIL(msg); return; } \
} while(0)

#define ASSERT_EQUAL(a, b, msg) do { \
    if ((a) != (b)) { TEST_FAIL(msg); return; } \
} while(0)

#define ASSERT_STR_EQUAL(a, b, msg) do { \
    if (strcmp((a), (b)) != 0) { TEST_FAIL(msg); return; } \
} while(0)

#define ASSERT_NOT_NULL(ptr, msg) do { \
    if ((ptr) == NULL) { TEST_FAIL(msg); return; } \
} while(0)

/* ============================================================================
 * 辅助函数
 * ============================================================================ */

/* 创建一个临时测试文件 */
static void create_temp_file(const char* path, const char* content)
{
    FILE* f = fopen(path, "w");
    if (f) {
        fprintf(f, "%s", content);
        fclose(f);
    }
}

/* 创建临时目录 */
static void create_temp_dir(const char* path)
{
    mkdir(path, 0755);
}

/* 删除文件或目录（递归） */
static void remove_path(const char* path)
{
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "rm -rf %s", path);
    system(cmd);
}

/* 进度回调（空实现） */
static void progress_cb(VolInfo* volInfo)
{
    (void)volInfo;
}

static void write_progress_cb(VolInfo* volInfo, double percent)
{
    (void)volInfo;
    (void)percent;
}

/* ============================================================================
 * 测试 1: bk_init_vol_info 和 bk_destroy_vol_info
 * ============================================================================ */
static void test_init_destroy_vol_info(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_init_vol_info / bk_destroy_vol_info");

    /* 初始化 */
    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "bk_init_vol_info should return 1");

    /* 验证默认值 */
    ASSERT_TRUE(volInfo.dirTree.base.posixFileMode == 040755,
                "root dir should have mode 040755");
    ASSERT_TRUE(volInfo.posixFileDefaults == 0100644,
                "default file perms should be 0100644");
    ASSERT_TRUE(volInfo.posixDirDefaults == 040755,
                "default dir perms should be 040755");
    ASSERT_TRUE(volInfo.scanForDuplicateFiles == false,
                "scanForDuplicateFiles should be false");
    ASSERT_TRUE(volInfo.dirTree.children == NULL,
                "children should be NULL after init");

    /* 销毁 */
    bk_destroy_vol_info(&volInfo);

    /* 测试 scanForDuplicateFiles=true */
    rc = bk_init_vol_info(&volInfo, true);
    ASSERT_EQUAL(rc, 1, "bk_init_vol_info with scan=true should return 1");
    ASSERT_TRUE(volInfo.scanForDuplicateFiles == true,
                "scanForDuplicateFiles should be true");
    bk_destroy_vol_info(&volInfo);

    TEST_PASS();
}

/* ============================================================================
 * 测试 2: bk_init_vol_info 后多次 destroy 不崩溃
 * ============================================================================ */
static void test_double_destroy(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_destroy_vol_info 多次调用安全性");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "bk_init_vol_info should return 1");

    /* 第一次销毁 */
    bk_destroy_vol_info(&volInfo);

    /* 第二次销毁（不应崩溃）*/
    bk_destroy_vol_info(&volInfo);

    TEST_PASS();
}

/* ============================================================================
 * 测试 3: bk_get_error_string 和 bk_get_error_string_id
 * ============================================================================ */
static void test_error_strings(void)
{
    const char* str;

    TEST_START("bk_get_error_string / bk_get_error_string_id");

    /* 测试已知错误码 */
    str = bk_get_error_string(BKERROR_READ_GENERIC);
    ASSERT_NOT_NULL(str, "error string should not be NULL");
    ASSERT_STR_EQUAL(str, BKERROR_READ_GENERIC_TEXT,
                     "error string should match defined text");

    str = bk_get_error_string(BKERROR_OUT_OF_MEMORY);
    ASSERT_NOT_NULL(str, "error string should not be NULL");
    ASSERT_STR_EQUAL(str, BKERROR_OUT_OF_MEMORY_TEXT,
                     "error string should match defined text");

    str = bk_get_error_string(BKERROR_DIR_NOT_FOUND_ON_IMAGE);
    ASSERT_NOT_NULL(str, "error string should not be NULL");
    ASSERT_STR_EQUAL(str, BKERROR_DIR_NOT_FOUND_ON_IMAGE_TEXT,
                     "error string should match defined text");

    /* 测试 bk_get_error_string_id */
    str = bk_get_error_string_id(BKERROR_READ_GENERIC);
    ASSERT_NOT_NULL(str, "error string id should not be NULL");
    ASSERT_STR_EQUAL(str, "BKERROR_READ_GENERIC",
                     "error string id should match");

    str = bk_get_error_string_id(BKERROR_OUT_OF_MEMORY);
    ASSERT_NOT_NULL(str, "error string id should not be NULL");
    ASSERT_STR_EQUAL(str, "BKERROR_OUT_OF_MEMORY",
                     "error string id should match");

    str = bk_get_error_string_id(BKWARNING_OPER_PARTLY_FAILED);
    ASSERT_NOT_NULL(str, "warning string id should not be NULL");
    ASSERT_STR_EQUAL(str, "BKWARNING_OPER_PARTLY_FAILED",
                     "warning string id should match");

    /* 测试未知错误码 */
    str = bk_get_error_string_id(-999999);
    ASSERT_NOT_NULL(str, "unknown error string id should not be NULL");
    ASSERT_STR_EQUAL(str, "BKERROR_UNKNOWN",
                     "unknown error id should return BKERROR_UNKNOWN");

    TEST_PASS();
}

/* ============================================================================
 * 测试 4: bk_set_vol_name 和 bk_get_volume_name
 * ============================================================================ */
static void test_vol_name(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_set_vol_name / bk_get_volume_name");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 设置卷名 */
    rc = bk_set_vol_name(&volInfo, "TEST_VOL");
    ASSERT_EQUAL(rc, 1, "set_vol_name should succeed");

    /* 获取卷名 */
    const char* name = bk_get_volume_name(&volInfo);
    ASSERT_NOT_NULL(name, "volume name should not be NULL");
    ASSERT_STR_EQUAL(name, "TEST_VOL", "volume name should match");

    /* 测试长名称截断 */
    rc = bk_set_vol_name(&volInfo, "A_VERY_LONG_VOLUME_NAME_THAT_EXCEEDS_32_CHARS");
    ASSERT_EQUAL(rc, 1, "set_vol_name with long name should succeed");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 5: bk_set_publisher 和 bk_get_publisher
 * ============================================================================ */
static void test_publisher(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_set_publisher / bk_get_publisher");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 设置发布者 */
    rc = bk_set_publisher(&volInfo, "Test Publisher");
    ASSERT_EQUAL(rc, 1, "set_publisher should succeed");

    /* 获取发布者 */
    const char* pub = bk_get_publisher(&volInfo);
    ASSERT_NOT_NULL(pub, "publisher should not be NULL");
    ASSERT_STR_EQUAL(pub, "Test Publisher", "publisher should match");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 6: bk_cancel_operation
 * ============================================================================ */
static void test_cancel_operation(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_cancel_operation");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 初始状态不应有停止标志 */
    ASSERT_TRUE(volInfo.stopOperation == false,
                "stopOperation should be false initially");

    /* 取消操作 */
    bk_cancel_operation(&volInfo);
    ASSERT_TRUE(volInfo.stopOperation == true,
                "stopOperation should be true after cancel");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 7: bk_set_follow_symlinks
 * ============================================================================ */
static void test_follow_symlinks(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_set_follow_symlinks");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 默认不跟随 */
    ASSERT_TRUE(volInfo.followSymLinks == false,
                "followSymLinks should be false initially");

    /* 设置为跟随 */
    bk_set_follow_symlinks(&volInfo, true);
    ASSERT_TRUE(volInfo.followSymLinks == true,
                "followSymLinks should be true after set");

    /* 设置为不跟随 */
    bk_set_follow_symlinks(&volInfo, false);
    ASSERT_TRUE(volInfo.followSymLinks == false,
                "followSymLinks should be false after unset");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 8: bk_estimate_iso_size（空目录树）
 * ============================================================================ */
static void test_estimate_iso_size_empty(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_estimate_iso_size (空目录树)");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 空目录树的大小估算 */
    bk_off_t size = bk_estimate_iso_size(&volInfo, FNTYPE_9660);
    ASSERT_TRUE(size > 0, "estimated size should be > 0 for empty tree");

    /* Joliet 应该稍大 */
    bk_off_t size_joliet = bk_estimate_iso_size(&volInfo, FNTYPE_9660 | FNTYPE_JOLIET);
    ASSERT_TRUE(size_joliet >= size,
                "joliet size should be >= plain 9660 size");

    /* Rockridge 应该稍大 */
    bk_off_t size_rr = bk_estimate_iso_size(&volInfo, FNTYPE_9660 | FNTYPE_ROCKRIDGE);
    ASSERT_TRUE(size_rr >= size,
                "rockridge size should be >= plain 9660 size");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 9: bk_create_dir 创建目录
 * ============================================================================ */
static void test_create_dir(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_create_dir");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 在根目录创建子目录 */
    rc = bk_create_dir(&volInfo, "/", "testdir");
    ASSERT_EQUAL(rc, 1, "create_dir should succeed");

    /* 验证目录存在 */
    BkDir* foundDir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/testdir/", &foundDir);
    ASSERT_EQUAL(rc, 1, "get_dir_from_string should succeed");
    ASSERT_NOT_NULL(foundDir, "found directory should not be NULL");
    ASSERT_STR_EQUAL(foundDir->base.name, "testdir",
                     "directory name should be 'testdir'");
    ASSERT_TRUE(IS_DIR(foundDir->base.posixFileMode),
                "should be a directory");

    /* 创建重复目录应失败 */
    rc = bk_create_dir(&volInfo, "/", "testdir");
    ASSERT_TRUE(rc <= 0, "duplicate create_dir should fail");
    ASSERT_EQUAL(rc, BKERROR_DUPLICATE_CREATE_DIR,
                 "should return DUPLICATE_CREATE_DIR error");

    /* 创建嵌套目录 */
    rc = bk_create_dir(&volInfo, "/testdir/", "subdir");
    ASSERT_EQUAL(rc, 1, "create nested dir should succeed");

    BkDir* subDir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/testdir/subdir/", &subDir);
    ASSERT_EQUAL(rc, 1, "get nested dir should succeed");
    ASSERT_NOT_NULL(subDir, "nested dir should not be NULL");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 10: bk_create_dir 错误场景
 * ============================================================================ */
static void test_create_dir_errors(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_create_dir 错误场景");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 空名称应失败 */
    rc = bk_create_dir(&volInfo, "/", "");
    ASSERT_TRUE(rc <= 0, "blank name should fail");
    ASSERT_EQUAL(rc, BKERROR_BLANK_NAME, "should return BLANK_NAME error");

    /* 名称过长应失败 */
    char longName[300];
    memset(longName, 'a', sizeof(longName) - 1);
    longName[sizeof(longName) - 1] = '\0';
    rc = bk_create_dir(&volInfo, "/", longName);
    ASSERT_TRUE(rc <= 0, "long name should fail");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 11: bk_open_image 打开不存在的文件
 * ============================================================================ */
static void test_open_nonexistent_image(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_open_image (不存在的文件)");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 打开不存在的文件应失败 */
    rc = bk_open_image(&volInfo, "/tmp/nonexistent_iso_test_file.iso");
    ASSERT_TRUE(rc <= 0, "open nonexistent file should fail");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 12: 完整的 ISO 创建和写入流程
 * 创建 ISO -> 添加目录和文件 -> 写入 -> 重新读取验证
 * ============================================================================ */
static void test_create_and_write_iso(void)
{
    VolInfo volInfo;
    int rc;
    const char* isoPath = "/tmp/test_bk_output.iso";
    const char* testFilePath = "/tmp/test_bk_input_file.txt";

    TEST_START("创建 ISO 并写入文件");

    /* 创建测试输入文件 */
    create_temp_file(testFilePath, "Hello, ISO Master Test!\n");

    /* 初始化 */
    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 设置卷名 */
    rc = bk_set_vol_name(&volInfo, "TESTDISC");
    ASSERT_EQUAL(rc, 1, "set vol name should succeed");

    /* 创建目录结构 */
    rc = bk_create_dir(&volInfo, "/", "docs");
    ASSERT_EQUAL(rc, 1, "create docs dir should succeed");

    rc = bk_create_dir(&volInfo, "/", "data");
    ASSERT_EQUAL(rc, 1, "create data dir should succeed");

    /* 添加文件到根目录 */
    rc = bk_add(&volInfo, testFilePath, "/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file to root should succeed");

    /* 添加文件到子目录 */
    rc = bk_add(&volInfo, testFilePath, "/docs/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file to docs should succeed");

    /* 估算大小 */
    bk_off_t estimatedSize = bk_estimate_iso_size(&volInfo,
                                                   FNTYPE_9660 | FNTYPE_ROCKRIDGE);
    ASSERT_TRUE(estimatedSize > 0, "estimated size should be > 0");

    /* 删除旧的 ISO 文件（如果存在） */
    unlink(isoPath);

    /* 写入 ISO */
    rc = bk_write_image(isoPath, &volInfo, time(NULL),
                        FNTYPE_9660 | FNTYPE_ROCKRIDGE,
                        write_progress_cb);
    ASSERT_EQUAL(rc, 1, "write_image should succeed");

    /* 验证 ISO 文件存在 */
    struct stat st;
    rc = stat(isoPath, &st);
    ASSERT_EQUAL(rc, 0, "ISO file should exist");
    ASSERT_TRUE(st.st_size > 0, "ISO file should have size > 0");

    bk_destroy_vol_info(&volInfo);

    /* 清理 */
    unlink(testFilePath);

    TEST_PASS();
}

/* ============================================================================
 * 测试 13: 读取 ISO 文件（需要先创建）
 * ============================================================================ */
static void test_read_iso(void)
{
    VolInfo volInfo;
    int rc;
    const char* isoPath = "/tmp/test_bk_read_test.iso";
    const char* testFilePath = "/tmp/test_bk_read_input.txt";

    TEST_START("读取 ISO 文件并验证目录树");

    /* 第一步：创建一个 ISO 文件 */
    create_temp_file(testFilePath, "Read test content\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_set_vol_name(&volInfo, "READTEST");
    ASSERT_EQUAL(rc, 1, "set vol name should succeed");

    rc = bk_create_dir(&volInfo, "/", "mydir");
    ASSERT_EQUAL(rc, 1, "create dir should succeed");

    rc = bk_add(&volInfo, testFilePath, "/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    rc = bk_add(&volInfo, testFilePath, "/mydir/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file to mydir should succeed");

    unlink(isoPath);
    rc = bk_write_image(isoPath, &volInfo, time(NULL),
                        FNTYPE_9660,
                        write_progress_cb);
    ASSERT_EQUAL(rc, 1, "write_image should succeed");

    bk_destroy_vol_info(&volInfo);

    /* 第二步：读取 ISO 文件 */
    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init for reading should succeed");

    rc = bk_open_image(&volInfo, isoPath);
    ASSERT_EQUAL(rc, 1, "open_image should succeed");

    rc = bk_read_vol_info(&volInfo);
    ASSERT_EQUAL(rc, 1, "read_vol_info should succeed");

    /* 验证卷名 */
    const char* volName = bk_get_volume_name(&volInfo);
    ASSERT_NOT_NULL(volName, "volume name should not be NULL");
    ASSERT_STR_EQUAL(volName, "READTEST", "volume name should match");

    /* 读取目录树（使用 9660 类型） */
    rc = bk_read_dir_tree(&volInfo, FNTYPE_9660, false, progress_cb);
    ASSERT_TRUE(rc > 0, "read_dir_tree should succeed (rc > 0)");

    /* 验证根目录有子项 */
    ASSERT_NOT_NULL(volInfo.dirTree.children,
                    "root should have children");

    /* 遍历子项查找目录（ISO 9660 可能会改变大小写） */
    BkDir* foundDir = NULL;
    BkFileBase* child = volInfo.dirTree.children;
    while (child != NULL) {
        if (IS_DIR(child->posixFileMode)) {
            foundDir = BK_DIR_PTR(child);
            break;
        }
        child = child->next;
    }
    ASSERT_NOT_NULL(foundDir, "should find a directory in root");

    bk_destroy_vol_info(&volInfo);

    /* 清理 */
    unlink(isoPath);
    unlink(testFilePath);

    TEST_PASS();
}

/* ============================================================================
 * 测试 14: bk_add 添加文件到 ISO
 * ============================================================================ */
static void test_add_file(void)
{
    VolInfo volInfo;
    int rc;
    const char* testFile = "/tmp/test_bk_add_file.txt";

    TEST_START("bk_add 添加文件到 ISO");

    create_temp_file(testFile, "Add test content\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 添加文件到根目录 */
    rc = bk_add(&volInfo, testFile, "/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    /* 重复添加应失败 */
    rc = bk_add(&volInfo, testFile, "/", progress_cb);
    ASSERT_TRUE(rc <= 0, "duplicate add should fail");
    ASSERT_EQUAL(rc, BKERROR_DUPLICATE_ADD,
                 "should return DUPLICATE_ADD error");

    bk_destroy_vol_info(&volInfo);
    unlink(testFile);

    TEST_PASS();
}

/* ============================================================================
 * 测试 15: bk_add_as 重命名添加文件
 * ============================================================================ */
static void test_add_as(void)
{
    VolInfo volInfo;
    int rc;
    const char* testFile = "/tmp/test_bk_add_as.txt";

    TEST_START("bk_add_as 重命名添加文件");

    create_temp_file(testFile, "Add as test content\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 使用不同名称添加 */
    rc = bk_add_as(&volInfo, testFile, "/", "renamed.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add_as should succeed");

    bk_destroy_vol_info(&volInfo);
    unlink(testFile);

    TEST_PASS();
}

/* ============================================================================
 * 测试 16: bk_delete 从 ISO 删除文件
 * ============================================================================ */
static void test_delete_file(void)
{
    VolInfo volInfo;
    int rc;
    const char* testFile = "/tmp/test_bk_delete_file.txt";
    const char* isoPath = "/tmp/test_bk_delete.iso";

    TEST_START("bk_delete 从 ISO 删除文件");

    /* 创建 ISO（使用 8.3 格式文件名） */
    create_temp_file(testFile, "Delete test content\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_create_dir(&volInfo, "/", "mydir");
    ASSERT_EQUAL(rc, 1, "create dir should succeed");

    rc = bk_add_as(&volInfo, testFile, "/", "test.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    rc = bk_add_as(&volInfo, testFile, "/mydir/", "test.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file to mydir should succeed");

    /* 删除根目录下的文件 */
    rc = bk_delete(&volInfo, "/test.txt");
    ASSERT_EQUAL(rc, 1, "delete file should succeed");

    /* 删除不存在的文件（库会静默成功） */
    rc = bk_delete(&volInfo, "/nonexist.txt");
    ASSERT_EQUAL(rc, 1, "delete nonexistent returns 1 (silent success)");

    /* 删除根目录应失败 */
    rc = bk_delete(&volInfo, "/");
    ASSERT_TRUE(rc <= 0, "delete root should fail");
    ASSERT_EQUAL(rc, BKERROR_DELETE_ROOT,
                 "should return DELETE_ROOT error");

    /* 删除 mydir 下的文件 */
    rc = bk_delete(&volInfo, "/mydir/test.txt");
    ASSERT_EQUAL(rc, 1, "delete file from mydir should succeed");

    /* 删除 mydir 目录 */
    rc = bk_delete(&volInfo, "/mydir");
    ASSERT_EQUAL(rc, 1, "delete mydir should succeed");

    bk_destroy_vol_info(&volInfo);
    unlink(testFile);
    unlink(isoPath);

    TEST_PASS();
}

/* ============================================================================
 * 测试 17: bk_rename 重命名文件
 * ============================================================================ */
static void test_rename(void)
{
    VolInfo volInfo;
    int rc;
    const char* testFile = "/tmp/test_bk_rename.txt";

    TEST_START("bk_rename 重命名文件");

    create_temp_file(testFile, "Rename test content\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_add(&volInfo, testFile, "/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    /* 获取文件名 */
    char* baseName = strrchr(testFile, '/');
    if (baseName) baseName++; else baseName = (char*)testFile;
    char filePath[256];
    snprintf(filePath, sizeof(filePath), "/%s", baseName);

    /* 重命名 */
    rc = bk_rename(&volInfo, filePath, "newname.txt");
    ASSERT_EQUAL(rc, 1, "rename should succeed");

    /* 重命名不存在的文件应失败 */
    rc = bk_rename(&volInfo, "/nonexistent.txt", "new.txt");
    ASSERT_TRUE(rc <= 0, "rename nonexistent should fail");

    /* 重命名根目录应失败 */
    rc = bk_rename(&volInfo, "/", "newroot");
    ASSERT_TRUE(rc <= 0, "rename root should fail");
    ASSERT_EQUAL(rc, BKERROR_RENAME_ROOT,
                 "should return RENAME_ROOT error");

    /* 空名称应失败 */
    rc = bk_rename(&volInfo, "/newname.txt", "");
    ASSERT_TRUE(rc <= 0, "rename with blank name should fail");
    ASSERT_EQUAL(rc, BKERROR_BLANK_NAME,
                 "should return BLANK_NAME error");

    bk_destroy_vol_info(&volInfo);
    unlink(testFile);

    TEST_PASS();
}

/* ============================================================================
 * 测试 18: bk_set_permissions / bk_get_permissions
 * ============================================================================ */
static void test_permissions(void)
{
    VolInfo volInfo;
    int rc;
    const char* testFile = "/tmp/test_bk_perms.txt";
    mode_t perms;

    TEST_START("bk_set_permissions / bk_get_permissions");

    create_temp_file(testFile, "Permissions test\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_add(&volInfo, testFile, "/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    char* baseName = strrchr(testFile, '/');
    if (baseName) baseName++; else baseName = (char*)testFile;
    char filePath[256];
    snprintf(filePath, sizeof(filePath), "/%s", baseName);

    /* 获取默认权限 */
    rc = bk_get_permissions(&volInfo, filePath, &perms);
    ASSERT_EQUAL(rc, 1, "get_permissions should succeed");

    /* 设置新权限 */
    rc = bk_set_permissions(&volInfo, filePath, 0755);
    ASSERT_EQUAL(rc, 1, "set_permissions should succeed");

    /* 验证权限 */
    rc = bk_get_permissions(&volInfo, filePath, &perms);
    ASSERT_EQUAL(rc, 1, "get_permissions should succeed");
    ASSERT_EQUAL(perms, 0755, "permissions should be 0755");

    /* 再次修改权限 */
    rc = bk_set_permissions(&volInfo, filePath, 0644);
    ASSERT_EQUAL(rc, 1, "set_permissions should succeed");

    rc = bk_get_permissions(&volInfo, filePath, &perms);
    ASSERT_EQUAL(rc, 1, "get_permissions should succeed");
    ASSERT_EQUAL(perms, 0644, "permissions should be 0644");

    /* 对不存在的文件设置权限应失败 */
    rc = bk_set_permissions(&volInfo, "/nonexistent.txt", 0755);
    ASSERT_TRUE(rc <= 0, "set permissions on nonexistent should fail");
    ASSERT_EQUAL(rc, BKERROR_ITEM_NOT_FOUND_ON_IMAGE,
                 "should return ITEM_NOT_FOUND error");

    /* NULL 参数应失败 */
    rc = bk_get_permissions(&volInfo, filePath, NULL);
    ASSERT_TRUE(rc <= 0, "get_permissions with NULL should fail");
    ASSERT_EQUAL(rc, BKERROR_GET_PERM_BAD_PARAM,
                 "should return GET_PERM_BAD_PARAM error");

    bk_destroy_vol_info(&volInfo);
    unlink(testFile);

    TEST_PASS();
}

/* ============================================================================
 * 测试 19: bk_extract 从 ISO 提取文件
 * ============================================================================ */
static void test_extract(void)
{
    VolInfo volInfo;
    int rc;
    const char* isoPath = "/tmp/test_bk_extract.iso";
    const char* testFile = "/tmp/test_bk_extract_input.txt";
    const char* extractDir = "/tmp/test_bk_extract_dir";

    TEST_START("bk_extract 从 ISO 提取文件");

    /* 创建 ISO（使用 8.3 格式的文件名避免 mangling） */
    create_temp_file(testFile, "Extract test content line1\nline2\nline3\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_create_dir(&volInfo, "/", "docs");
    ASSERT_EQUAL(rc, 1, "create dir should succeed");

    /* 使用 8.3 格式的文件名添加 */
    rc = bk_add_as(&volInfo, testFile, "/", "test.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    rc = bk_add_as(&volInfo, testFile, "/docs/", "test.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file to docs should succeed");

    unlink(isoPath);
    rc = bk_write_image(isoPath, &volInfo, time(NULL),
                        FNTYPE_9660,
                        write_progress_cb);
    ASSERT_EQUAL(rc, 1, "write_image should succeed");

    bk_destroy_vol_info(&volInfo);

    /* 第二步：读取 ISO 并提取文件 */
    remove_path(extractDir);
    create_temp_dir(extractDir);

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_open_image(&volInfo, isoPath);
    ASSERT_EQUAL(rc, 1, "open_image should succeed");

    rc = bk_read_vol_info(&volInfo);
    ASSERT_EQUAL(rc, 1, "read_vol_info should succeed");

    /* 使用 9660 类型读取 */
    rc = bk_read_dir_tree(&volInfo, FNTYPE_9660, false, progress_cb);
    ASSERT_TRUE(rc > 0, "read_dir_tree should succeed (rc > 0)");

    /* 查找根目录下的第一个文件 */
    BkFileBase* child = volInfo.dirTree.children;
    BkFile* firstFile = NULL;
    while (child != NULL) {
        if (IS_REG_FILE(child->posixFileMode)) {
            firstFile = BK_FILE_PTR(child);
            break;
        }
        child = child->next;
    }
    ASSERT_NOT_NULL(firstFile, "should find a file in root");

    /* 提取该文件到目标目录 */
    char extractFilePath[512];
    snprintf(extractFilePath, sizeof(extractFilePath), "/%s", firstFile->base.name);
    rc = bk_extract(&volInfo, extractFilePath, extractDir, false, progress_cb);
    ASSERT_EQUAL(rc, 1, "extract file should succeed");

    /* 验证提取的文件存在 */
    char extractedPath[1024];
    snprintf(extractedPath, sizeof(extractedPath), "%s/%s", extractDir, firstFile->base.name);
    struct stat st;
    rc = stat(extractedPath, &st);
    ASSERT_EQUAL(rc, 0, "extracted file should exist");
    ASSERT_TRUE(st.st_size > 0, "extracted file should have size > 0");

    /* 提取根目录应失败 */
    rc = bk_extract(&volInfo, "/", extractDir, false, progress_cb);
    ASSERT_TRUE(rc <= 0, "extract root should fail");
    ASSERT_EQUAL(rc, BKERROR_EXTRACT_ROOT,
                 "should return EXTRACT_ROOT error");

    bk_destroy_vol_info(&volInfo);

    /* 清理 */
    unlink(isoPath);
    unlink(testFile);
    remove_path(extractDir);

    TEST_PASS();
}

/* ============================================================================
 * 测试 20: 完整的写入-读取-修改-再写入流程
 * ============================================================================ */
static void test_full_workflow(void)
{
    VolInfo volInfo;
    int rc;
    const char* isoPath1 = "/tmp/test_bk_workflow1.iso";
    const char* isoPath2 = "/tmp/test_bk_workflow2.iso";
    const char* testFile1 = "/tmp/test_bk_wf_file1.txt";
    const char* testFile2 = "/tmp/test_bk_wf_file2.txt";

    TEST_START("完整工作流: 创建->写入->读取->修改->再写入");

    /* 创建测试文件 */
    create_temp_file(testFile1, "File 1 content\n");
    create_temp_file(testFile2, "File 2 content\n");

    /* === 第一阶段：创建 ISO === */
    rc = bk_init_vol_info(&volInfo, true);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_set_vol_name(&volInfo, "WORKFLOW");
    ASSERT_EQUAL(rc, 1, "set vol name should succeed");

    rc = bk_set_publisher(&volInfo, "Test Publisher");
    ASSERT_EQUAL(rc, 1, "set publisher should succeed");

    rc = bk_create_dir(&volInfo, "/", "dir1");
    ASSERT_EQUAL(rc, 1, "create dir1 should succeed");

    rc = bk_create_dir(&volInfo, "/", "dir2");
    ASSERT_EQUAL(rc, 1, "create dir2 should succeed");

    /* 使用 8.3 格式的文件名 */
    rc = bk_add_as(&volInfo, testFile1, "/", "file1.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file1 should succeed");

    rc = bk_add_as(&volInfo, testFile2, "/dir1/", "file2.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file2 to dir1 should succeed");

    unlink(isoPath1);
    rc = bk_write_image(isoPath1, &volInfo, time(NULL),
                        FNTYPE_9660,
                        write_progress_cb);
    ASSERT_EQUAL(rc, 1, "write first ISO should succeed");

    bk_destroy_vol_info(&volInfo);

    /* === 第二阶段：读取并修改 === */
    rc = bk_init_vol_info(&volInfo, true);
    ASSERT_EQUAL(rc, 1, "init for reading should succeed");

    rc = bk_open_image(&volInfo, isoPath1);
    ASSERT_EQUAL(rc, 1, "open first ISO should succeed");

    rc = bk_read_vol_info(&volInfo);
    ASSERT_EQUAL(rc, 1, "read vol info should succeed");

    /* 验证卷名 */
    const char* volName = bk_get_volume_name(&volInfo);
    ASSERT_STR_EQUAL(volName, "WORKFLOW", "vol name should be WORKFLOW");

    /* 使用 9660 类型读取 */
    rc = bk_read_dir_tree(&volInfo, FNTYPE_9660, false, progress_cb);
    ASSERT_TRUE(rc > 0, "read dir tree should succeed (rc > 0)");

    /* 修改：添加新文件（使用 8.3 格式） */
    rc = bk_add_as(&volInfo, testFile2, "/", "file2.txt", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file2 to root should succeed");

    /* 修改：创建新目录 */
    rc = bk_create_dir(&volInfo, "/", "dir3");
    ASSERT_EQUAL(rc, 1, "create dir3 should succeed");

    /* 修改：删除文件（使用 8.3 格式） */
    rc = bk_delete(&volInfo, "/file1.txt");
    ASSERT_EQUAL(rc, 1, "delete file1 should succeed");

    /* === 第三阶段：写入修改后的 ISO === */
    unlink(isoPath2);
    rc = bk_write_image(isoPath2, &volInfo, time(NULL),
                        FNTYPE_9660,
                        write_progress_cb);
    ASSERT_EQUAL(rc, 1, "write second ISO should succeed");

    bk_destroy_vol_info(&volInfo);

    /* === 第四阶段：验证修改后的 ISO === */
    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init for verification should succeed");

    rc = bk_open_image(&volInfo, isoPath2);
    ASSERT_EQUAL(rc, 1, "open second ISO should succeed");

    rc = bk_read_vol_info(&volInfo);
    ASSERT_EQUAL(rc, 1, "read vol info should succeed");

    /* 使用 9660 类型读取 */
    rc = bk_read_dir_tree(&volInfo, FNTYPE_9660, false, progress_cb);
    ASSERT_TRUE(rc > 0, "read dir tree should succeed (rc > 0)");

    /* 验证根目录有子项 */
    ASSERT_NOT_NULL(volInfo.dirTree.children,
                    "root should have children");

    /* 统计目录和文件数量 */
    int dirCount = 0;
    int fileCount = 0;
    BkFileBase* child = volInfo.dirTree.children;
    while (child != NULL) {
        if (IS_DIR(child->posixFileMode))
            dirCount++;
        else if (IS_REG_FILE(child->posixFileMode))
            fileCount++;
        child = child->next;
    }

    /* 应该有 3 个目录 (dir1, dir2, dir3) 和至少 1 个文件 */
    ASSERT_TRUE(dirCount >= 3, "should have at least 3 directories");
    ASSERT_TRUE(fileCount >= 1, "should have at least 1 file");

    bk_destroy_vol_info(&volInfo);

    /* 清理 */
    unlink(isoPath1);
    unlink(isoPath2);
    unlink(testFile1);
    unlink(testFile2);

    TEST_PASS();
}

/* ============================================================================
 * 测试 21: bk_get_dir_from_string 路径解析
 * ============================================================================ */
static void test_get_dir_from_string(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_get_dir_from_string 路径解析");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 创建目录结构 */
    rc = bk_create_dir(&volInfo, "/", "level1");
    ASSERT_EQUAL(rc, 1, "create level1 should succeed");

    rc = bk_create_dir(&volInfo, "/level1/", "level2");
    ASSERT_EQUAL(rc, 1, "create level2 should succeed");

    rc = bk_create_dir(&volInfo, "/level1/level2/", "level3");
    ASSERT_EQUAL(rc, 1, "create level3 should succeed");

    /* 测试根目录 */
    BkDir* dir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/", &dir);
    ASSERT_EQUAL(rc, 1, "get root should succeed");
    ASSERT_NOT_NULL(dir, "root dir should not be NULL");

    /* 测试一级目录 */
    dir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/level1/", &dir);
    ASSERT_EQUAL(rc, 1, "get level1 should succeed");
    ASSERT_NOT_NULL(dir, "level1 should not be NULL");
    ASSERT_STR_EQUAL(dir->base.name, "level1", "name should be level1");

    /* 测试二级目录 */
    dir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/level1/level2/", &dir);
    ASSERT_EQUAL(rc, 1, "get level2 should succeed");
    ASSERT_NOT_NULL(dir, "level2 should not be NULL");
    ASSERT_STR_EQUAL(dir->base.name, "level2", "name should be level2");

    /* 测试三级目录 */
    dir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/level1/level2/level3/", &dir);
    ASSERT_EQUAL(rc, 1, "get level3 should succeed");
    ASSERT_NOT_NULL(dir, "level3 should not be NULL");
    ASSERT_STR_EQUAL(dir->base.name, "level3", "name should be level3");

    /* 测试不存在的路径 */
    dir = NULL;
    rc = bk_get_dir_from_string(&volInfo, "/nonexistent/", &dir);
    ASSERT_TRUE(rc <= 0, "nonexistent path should fail");
    ASSERT_EQUAL(rc, BKERROR_DIR_NOT_FOUND_ON_IMAGE,
                 "should return DIR_NOT_FOUND error");

    /* 测试格式错误的路径 */
    rc = bk_get_dir_from_string(&volInfo, "level1/", &dir);
    ASSERT_TRUE(rc <= 0, "path without leading slash should fail");

    rc = bk_get_dir_from_string(&volInfo, "/level1", &dir);
    ASSERT_TRUE(rc <= 0, "path without trailing slash should fail");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 22: bk_get_boot_media_type / bk_get_boot_record_size
 * ============================================================================ */
static void test_boot_info(void)
{
    VolInfo volInfo;
    int rc;

    TEST_START("bk_get_boot_media_type / bk_get_boot_record_size");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 默认无引导 */
    ASSERT_EQUAL(volInfo.bootMediaType, BOOT_MEDIA_NONE,
                 "default boot media type should be NONE");

    unsigned char bootType = bk_get_boot_media_type(&volInfo);
    ASSERT_EQUAL(bootType, BOOT_MEDIA_NONE,
                 "get_boot_media_type should return NONE");

    unsigned bootSize = bk_get_boot_record_size(&volInfo);
    ASSERT_EQUAL(bootSize, 0,
                 "get_boot_record_size should return 0");

    bk_destroy_vol_info(&volInfo);
    TEST_PASS();
}

/* ============================================================================
 * 测试 23: 大量文件添加和删除
 * ============================================================================ */
static void test_many_files(void)
{
    VolInfo volInfo;
    int rc;
    const char* testFile = "/tmp/test_bk_many.txt";
    int i;

    TEST_START("大量文件添加和删除 (压力测试)");

    create_temp_file(testFile, "Many files test\n");

    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    /* 添加多个目录 */
    for (i = 0; i < 10; i++) {
        char dirName[32];
        snprintf(dirName, sizeof(dirName), "dir%02d", i);
        rc = bk_create_dir(&volInfo, "/", dirName);
        ASSERT_EQUAL(rc, 1, "create dir should succeed");
    }

    /* 添加多个文件到不同目录 */
    for (i = 0; i < 10; i++) {
        char destPath[64];
        snprintf(destPath, sizeof(destPath), "/dir%02d/", i);
        rc = bk_add_as(&volInfo, testFile, destPath, "testfile.txt", progress_cb);
        ASSERT_EQUAL(rc, 1, "add file should succeed");
    }

    /* 删除所有目录 */
    for (i = 0; i < 10; i++) {
        char dirName[32];
        snprintf(dirName, sizeof(dirName), "/dir%02d", i);
        rc = bk_delete(&volInfo, dirName);
        ASSERT_EQUAL(rc, 1, "delete dir should succeed");
    }

    /* 验证根目录为空 */
    ASSERT_TRUE(volInfo.dirTree.children == NULL,
                "root should have no children after deletion");

    bk_destroy_vol_info(&volInfo);
    unlink(testFile);

    TEST_PASS();
}

/* ============================================================================
 * 测试 24: bk_write_image 覆盖保护
 * ============================================================================ */
static void test_save_overwrite_protection(void)
{
    VolInfo volInfo;
    int rc;
    const char* isoPath = "/tmp/test_bk_overwrite.iso";
    const char* testFile = "/tmp/test_bk_overwrite_input.txt";

    TEST_START("bk_write_image 覆盖保护");

    create_temp_file(testFile, "Overwrite test\n");

    /* 创建第一个 ISO */
    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_add(&volInfo, testFile, "/", progress_cb);
    ASSERT_EQUAL(rc, 1, "add file should succeed");

    unlink(isoPath);
    rc = bk_write_image(isoPath, &volInfo, time(NULL),
                        FNTYPE_9660, write_progress_cb);
    ASSERT_EQUAL(rc, 1, "first write should succeed");

    bk_destroy_vol_info(&volInfo);

    /* 读取 ISO 并尝试覆盖原文件 */
    rc = bk_init_vol_info(&volInfo, false);
    ASSERT_EQUAL(rc, 1, "init should succeed");

    rc = bk_open_image(&volInfo, isoPath);
    ASSERT_EQUAL(rc, 1, "open should succeed");

    rc = bk_read_vol_info(&volInfo);
    ASSERT_EQUAL(rc, 1, "read vol info should succeed");

    /* 使用 9660 类型读取（因为写入时只用了 9660） */
    rc = bk_read_dir_tree(&volInfo, FNTYPE_9660, false, progress_cb);
    ASSERT_TRUE(rc > 0, "read dir tree should succeed (rc > 0)");

    /* 尝试覆盖原文件（应该失败） */
    rc = bk_write_image(isoPath, &volInfo, time(NULL),
                        FNTYPE_9660, write_progress_cb);
    ASSERT_TRUE(rc <= 0, "overwrite should fail");
    ASSERT_EQUAL(rc, BKERROR_SAVE_OVERWRITE,
                 "should return SAVE_OVERWRITE error");

    bk_destroy_vol_info(&volInfo);

    /* 清理 */
    unlink(isoPath);
    unlink(testFile);

    TEST_PASS();
}

/* ============================================================================
 * 主函数
 * ============================================================================ */
int main(void)
{
    printf("\n");
    printf("========================================\n");
    printf("  bkisofs 单元测试\n");
    printf("========================================\n\n");

    printf("[组 1] 内存管理\n");
    test_init_destroy_vol_info();
    test_double_destroy();

    printf("\n[组 2] 错误处理\n");
    test_error_strings();

    printf("\n[组 3] 属性操作\n");
    test_vol_name();
    test_publisher();
    test_cancel_operation();
    test_follow_symlinks();

    printf("\n[组 4] 大小估算\n");
    test_estimate_iso_size_empty();

    printf("\n[组 5] 目录操作\n");
    test_create_dir();
    test_create_dir_errors();
    test_get_dir_from_string();

    printf("\n[组 6] 文件打开\n");
    test_open_nonexistent_image();

    printf("\n[组 7] 文件操作\n");
    test_add_file();
    test_add_as();
    test_delete_file();
    test_rename();
    test_permissions();

    printf("\n[组 8] ISO 读写\n");
    test_create_and_write_iso();
    test_read_iso();
    test_extract();
    test_save_overwrite_protection();

    printf("\n[组 9] 引导信息\n");
    test_boot_info();

    printf("\n[组 10] 压力测试\n");
    test_many_files();

    printf("\n[组 11] 完整工作流\n");
    test_full_workflow();

    printf("\n========================================\n");
    printf("  测试结果汇总\n");
    printf("========================================\n");
    printf("  总计: %d\n", tests_run);
    printf("  通过: %d\n", tests_passed);
    printf("  失败: %d\n", tests_failed);
    printf("========================================\n\n");

    return (tests_failed > 0) ? 1 : 0;
}
