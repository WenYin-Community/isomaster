[CCode (cheader_filename = "iniparser.h")]
namespace Ini {
    [CCode (cname = "dictionary", has_type_id = false, free_function = "dictionary_del")]
    [Compact]
    public class Dictionary {
    }

    [CCode (cname = "iniparser_load")]
    public static Dictionary? load(string filename);

    [CCode (cname = "iniparser_getstring")]
    public static unowned string? get_string(Dictionary dict, string key, string? def);

    [CCode (cname = "iniparser_getint")]
    public static int get_int(Dictionary dict, string key, int def);

    [CCode (cname = "iniparser_getboolean")]
    public static int get_boolean(Dictionary dict, string key, int def);
}
