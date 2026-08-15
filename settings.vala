/*
 * ISO Master - application settings model and persistence
 */

// Application settings
public class AppSettings : Object {
    public int window_width { get; set; default = 800; }
    public int window_height { get; set; default = 600; }
    public int top_pane_height { get; set; default = 300; }
    public bool show_hidden_files { get; set; default = false; }
    public bool sort_dirs_first { get; set; default = true; }
    public bool case_sensitive_sort { get; set; default = false; }
    public bool dark_mode { get; set; default = false; }
    public string? temp_dir { get; set; default = "/tmp"; }
    public string? editor { get; set; default = "leafpad"; }
    public string? viewer { get; set; default = "firefox"; }
    public string?[] recently_open { get; set; default = new string?[5]; }
    public string? last_iso_dir { get; set; }
}

// Settings persistence, backed by iniparser (same API for load and save)
public class SettingsStore : Object {
    public string get_path() {
        return Path.build_filename(Environment.get_user_config_dir(),
                                   "isomaster", "isomaster.conf");
    }

    public void load(AppSettings settings) {
        var dict = Ini.load(get_path());
        if (dict == null) {
            return;
        }

        settings.window_width = Ini.get_int(dict, "window:width", 800);
        settings.window_height = Ini.get_int(dict, "window:height", 600);
        settings.top_pane_height = Ini.get_int(dict, "window:topPaneHeight", 300);
        settings.show_hidden_files = Ini.get_boolean(dict, "browser:showHidden", 0) != 0;
        settings.sort_dirs_first = Ini.get_boolean(dict, "browser:sortDirsFirst", 1) != 0;
        settings.case_sensitive_sort = Ini.get_boolean(dict, "browser:caseSensitiveSort", 0) != 0;
        settings.dark_mode = Ini.get_boolean(dict, "ui:darkMode", 0) != 0;
        settings.editor = Ini.get_string(dict, "ui:editor", "leafpad");
        settings.viewer = Ini.get_string(dict, "ui:viewer", "firefox");
        settings.temp_dir = Ini.get_string(dict, "ui:tempDir", "/tmp");
    }

    public void save(AppSettings settings, int window_width, int window_height) {
        var dir = Path.get_dirname(get_path());
        DirUtils.create_with_parents(dir, 0755);

        // Capture the current window size
        settings.window_width = window_width;
        settings.window_height = window_height;

        // Write through the same iniparser API used for loading
        var dict = Ini.load(get_path());
        if (dict == null) {
            dict = Ini.new_dictionary(16);
        }
        Ini.set(dict, "window:width", settings.window_width.to_string());
        Ini.set(dict, "window:height", settings.window_height.to_string());
        Ini.set(dict, "window:topPaneHeight", settings.top_pane_height.to_string());
        Ini.set(dict, "browser:showHidden", settings.show_hidden_files ? "1" : "0");
        Ini.set(dict, "browser:sortDirsFirst", settings.sort_dirs_first ? "1" : "0");
        Ini.set(dict, "browser:caseSensitiveSort", settings.case_sensitive_sort ? "1" : "0");
        Ini.set(dict, "ui:darkMode", settings.dark_mode ? "1" : "0");
        Ini.set(dict, "ui:editor", settings.editor ?? "leafpad");
        Ini.set(dict, "ui:viewer", settings.viewer ?? "firefox");
        Ini.set(dict, "ui:tempDir", settings.temp_dir ?? "/tmp");

        var file = FileStream.open(get_path(), "w");
        if (file != null) {
            Ini.dump_ini(dict, file);
        }
    }
}
