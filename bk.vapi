[CCode (cheader_filename = "bk.h")]
namespace Bk {
    [CCode (cname = "bk_off_t", has_type_id = false)]
    public struct OffT {
        public int64 value;
    }

    // Use pointers for large opaque C structs
    [CCode (cname = "VolInfo", has_type_id = false)]
    [SimpleType]
    public struct VolInfo {
        // Large opaque struct - use raw memory
        public uint8 _data[206080];
    }

    [CCode (cname = "BkDir", has_type_id = false)]
    [SimpleType]
    public struct BkDir {
        public void* _data;
    }

    [CCode (cname = "bk_init_vol_info")]
    public static int init_vol_info(VolInfo* vol_info, bool scan_duplicates);

    [CCode (cname = "bk_open_image")]
    public static int open_image(VolInfo* vol_info, string filename);

    [CCode (cname = "bk_read_vol_info")]
    public static int read_vol_info(VolInfo* vol_info);

    [CCode (cname = "bk_get_error_string")]
    public static unowned string get_error_string(int error_id);

    [CCode (cname = "bk_get_volume_name")]
    public static unowned string? get_volume_name(VolInfo* vol_info);

    [CCode (cname = "bk_get_publisher")]
    public static unowned string? get_publisher(VolInfo* vol_info);

    [CCode (cname = "bk_write_image")]
    public static int write_image(string path, VolInfo* vol_info, int64 creation_time, int filename_types, void* progress_function);

    [CCode (cname = "bk_add")]
    public static int add(VolInfo* vol_info, string src_path, string dest_path, void* progress_function);

    [CCode (cname = "bk_extract")]
    public static int extract(VolInfo* vol_info, string src_path, string dest_path, bool keep_permissions, void* progress_function);

    [CCode (cname = "bk_delete")]
    public static int delete(VolInfo* vol_info, string path_and_name);

    [CCode (cname = "bk_create_dir")]
    public static int create_dir(VolInfo* vol_info, string dest_path, string name);

    [CCode (cname = "bk_rename")]
    public static int rename(VolInfo* vol_info, string src, string dest);

    [CCode (cname = "bk_estimate_iso_size")]
    public static OffT estimate_iso_size(VolInfo* vol_info, int filename_types);

    [CCode (cname = "bk_set_vol_name")]
    public static int set_vol_name(VolInfo* vol_info, string vol_name);

    [CCode (cname = "bk_set_publisher")]
    public static int set_publisher(VolInfo* vol_info, string publisher);

    [CCode (cname = "FNTYPE_9660")]
    public const int FNTYPE_9660;
    [CCode (cname = "FNTYPE_ROCKRIDGE")]
    public const int FNTYPE_ROCKRIDGE;
    [CCode (cname = "FNTYPE_JOLIET")]
    public const int FNTYPE_JOLIET;
}
