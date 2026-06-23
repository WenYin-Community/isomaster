[CCode (cheader_filename = "bk.h")]
namespace Bk {
    // Use pointers for large opaque C structs
    [CCode (cname = "VolInfo", has_type_id = false)]
    [SimpleType]
    public struct VolInfo {
        // Large opaque struct - use raw memory
        public uint8 _data[206080];
    }

    [CCode (cname = "BkFileBase", has_type_id = false)]
    [SimpleType]
    public struct BkFileBase {
        public char original9660name[15];
        public char name[256];
        public uint posixFileMode;
        public BkFileBase* next;
    }

    [CCode (cname = "BkDir", has_type_id = false)]
    [SimpleType]
    public struct BkDir {
        public BkFileBase base;
        public BkFileBase* children;
    }

    [CCode (cname = "BkFile", has_type_id = false)]
    [SimpleType]
    public struct BkFile {
        public BkFileBase base;
        public uint size;
        // Other fields omitted for simplicity
    }

    [CCode (cname = "bk_init_vol_info")]
    public static int init_vol_info(VolInfo* vol_info, bool scan_duplicates);

    [CCode (cname = "bk_cancel_operation")]
    public static void cancel_operation(VolInfo* vol_info);

    [CCode (cname = "bk_destroy_vol_info")]
    public static void destroy_vol_info(VolInfo* vol_info);

    [CCode (cname = "bk_open_image")]
    public static int open_image(VolInfo* vol_info, string filename);

    [CCode (cname = "bk_read_vol_info")]
    public static int read_vol_info(VolInfo* vol_info);

    [CCode (cname = "ProgressFunc", has_target = false)]
    public delegate void ProgressFunc(VolInfo* vol_info);

    [CCode (cname = "WriteProgressFunc", has_target = false)]
    public delegate void WriteProgressFunc(VolInfo* vol_info, double progress);

    [CCode (cname = "bk_read_dir_tree")]
    public static int read_dir_tree(VolInfo* vol_info, int filename_type, bool keep_posix_permissions, ProgressFunc? progress_function);

    [CCode (cname = "bk_get_dir_from_string")]
    public static int get_dir_from_string(VolInfo* vol_info, string path_str, out BkDir* dir_found);

    [CCode (cname = "bk_get_error_string")]
    public static unowned string get_error_string(int error_id);

    [CCode (cname = "bk_get_error_string_id")]
    public static unowned string get_error_string_id(int error_id);

    [CCode (cname = "bk_get_volume_name")]
    public static unowned string? get_volume_name(VolInfo* vol_info);

    [CCode (cname = "bk_get_publisher")]
    public static unowned string? get_publisher(VolInfo* vol_info);

    [CCode (cname = "bk_write_image")]
    public static int write_image(string path, VolInfo* vol_info, int64 creation_time, int filename_types, WriteProgressFunc? progress_function);

    [CCode (cname = "bk_add")]
    public static int add(VolInfo* vol_info, string src_path, string dest_path, ProgressFunc? progress_function);

    [CCode (cname = "bk_extract")]
    public static int extract(VolInfo* vol_info, string src_path, string dest_path, bool keep_permissions, ProgressFunc? progress_function);

    [CCode (cname = "bk_delete")]
    public static int delete(VolInfo* vol_info, string path_and_name);

    [CCode (cname = "bk_create_dir")]
    public static int create_dir(VolInfo* vol_info, string dest_path, string name);

    [CCode (cname = "bk_rename")]
    public static int rename(VolInfo* vol_info, string src, string dest);

    [CCode (cname = "bk_estimate_iso_size")]
    public static int64 estimate_iso_size(VolInfo* vol_info, int filename_types);

    [CCode (cname = "bk_set_vol_name")]
    public static int set_vol_name(VolInfo* vol_info, string vol_name);

    [CCode (cname = "bk_set_publisher")]
    public static int set_publisher(VolInfo* vol_info, string publisher);

    [CCode (cname = "bk_get_boot_media_type")]
    public static uint8 get_boot_media_type(VolInfo* vol_info);

    [CCode (cname = "bk_get_boot_record_size")]
    public static uint get_boot_record_size(VolInfo* vol_info);

    [CCode (cname = "bk_set_permissions")]
    public static int set_permissions(VolInfo* vol_info, string path_and_name, uint permissions);

    [CCode (cname = "bk_get_permissions")]
    public static int get_permissions(VolInfo* vol_info, string path_and_name, out uint permissions);

    [CCode (cname = "bk_add_boot_record")]
    public static int add_boot_record(VolInfo* vol_info, string src_path, int boot_media_type);

    [CCode (cname = "bk_delete_boot_record")]
    public static void delete_boot_record(VolInfo* vol_info);

    [CCode (cname = "bk_extract_boot_record")]
    public static int extract_boot_record(VolInfo* vol_info, string dest_path, uint dest_file_perms);

    [CCode (cname = "bk_set_boot_file")]
    public static int set_boot_file(VolInfo* vol_info, string src_path);

    [CCode (cname = "FNTYPE_9660")]
    public const int FNTYPE_9660;
    [CCode (cname = "FNTYPE_ROCKRIDGE")]
    public const int FNTYPE_ROCKRIDGE;
    [CCode (cname = "FNTYPE_JOLIET")]
    public const int FNTYPE_JOLIET;

    [CCode (cname = "BOOT_MEDIA_NONE")]
    public const int BOOT_MEDIA_NONE;
    [CCode (cname = "BOOT_MEDIA_NO_EMULATION")]
    public const int BOOT_MEDIA_NO_EMULATION;
    [CCode (cname = "BOOT_MEDIA_1_2_FLOPPY")]
    public const int BOOT_MEDIA_1_2_FLOPPY;
    [CCode (cname = "BOOT_MEDIA_1_44_FLOPPY")]
    public const int BOOT_MEDIA_1_44_FLOPPY;
    [CCode (cname = "BOOT_MEDIA_2_88_FLOPPY")]
    public const int BOOT_MEDIA_2_88_FLOPPY;
    [CCode (cname = "BOOT_MEDIA_HARD_DISK")]
    public const int BOOT_MEDIA_HARD_DISK;

    // POSIX file mode helpers
    [CCode (cname = "S_ISDIR")]
    public static bool S_ISDIR(uint mode);

    [CCode (cname = "S_ISREG")]
    public static bool S_ISREG(uint mode);

    [CCode (cname = "S_ISLNK")]
    public static bool S_ISLNK(uint mode);
}
