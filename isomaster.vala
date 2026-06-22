/*
 * ISO Master - GTK4 Vala Implementation
 * Main application and window
 */

// Application settings
public class AppSettings : Object {
    public int window_width { get; set; default = 800; }
    public int window_height { get; set; default = 600; }
    public int top_pane_height { get; set; default = 300; }
    public bool show_hidden_files { get; set; default = false; }
    public bool sort_dirs_first { get; set; default = true; }
    public bool case_sensitive_sort { get; set; default = false; }
    public string? temp_dir { get; set; default = "/tmp"; }
    public string? editor { get; set; default = "leafpad"; }
    public string? viewer { get; set; default = "firefox"; }
    public string?[] recently_open { get; set; default = new string?[5]; }
    public string? last_iso_dir { get; set; }
}

// File item model
public class FileItem : Object {
    public string name { get; set; }
    public string path { get; set; }
    public bool is_dir { get; set; }
    public string icon_name { get; set; }
    public int64 size { get; set; }
}

// Main application window
public class IsoMaster : Adw.Application {
    private Gtk.Window? main_window = null;
    private AppSettings settings;
    private Bk.VolInfo* vol_info = null;
    private bool iso_loaded = false;

    // File system browser widgets
    private Gtk.ListView fs_list_view;
    private GLib.ListStore fs_store;
    private Gtk.Entry fs_path_entry;

    // ISO browser widgets
    private Gtk.ListView iso_list_view;
    private GLib.ListStore iso_store;
    private Gtk.Entry iso_path_entry;
    private Gtk.Label iso_size_label;

    public IsoMaster() {
        Object (
            application_id: "org.littlesvr.ISOMaster",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
        settings = new AppSettings();
    }

    protected override void activate() {
        // Initialize bk library
        vol_info = (Bk.VolInfo*) GLib.malloc(sizeof(Bk.VolInfo));
        Bk.init_vol_info(vol_info, false);

        // Load settings
        load_settings();

        // Create main window
        main_window = new Gtk.ApplicationWindow(this);
        main_window.title = "ISO Master";
        main_window.default_width = settings.window_width;
        main_window.default_height = settings.window_height;

        // Build UI
        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_window.child = main_box;

        // Menu bar
        var menubar = build_menubar();
        this.set_menubar(menubar);

        // Toolbar
        var toolbar = build_toolbar();
        main_box.append(toolbar);

        // Main content - horizontal paned
        var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
        paned.vexpand = true;

        // Left pane - file system browser
        var fs_box = build_fs_browser();
        paned.start_child = fs_box;
        paned.resize_start_child = true;
        paned.shrink_start_child = false;

        // Right pane - ISO browser
        var iso_box = build_iso_browser();
        paned.end_child = iso_box;
        paned.resize_end_child = true;
        paned.shrink_end_child = false;

        main_box.append(paned);

        // Connect close signal
        main_window.close_request.connect(() => {
            save_settings();
            return false;
        });

        main_window.present();
    }

    private GLib.Menu build_menubar() {
        var menubar = new GLib.Menu();

        // File menu
        var file_menu = new GLib.Menu();
        file_menu.append("_New", "app.new");
        file_menu.append("_Open", "app.open");
        file_menu.append("_Save", "app.save");
        file_menu.append("_Quit", "app.quit");
        menubar.append_submenu("_File", file_menu);

        // View menu
        var view_menu = new GLib.Menu();
        view_menu.append("_Refresh", "app.refresh");
        menubar.append_submenu("_View", view_menu);

        // Help menu
        var help_menu = new GLib.Menu();
        help_menu.append("_About", "app.about");
        menubar.append_submenu("_Help", help_menu);

        // Setup actions
        setup_actions();

        return menubar;
    }

    private void setup_actions() {
        var new_action = new GLib.SimpleAction("new", null);
        new_action.activate.connect(() => new_iso());
        this.add_action(new_action);

        var open_action = new GLib.SimpleAction("open", null);
        open_action.activate.connect(() => open_iso());
        this.add_action(open_action);

        var save_action = new GLib.SimpleAction("save", null);
        save_action.activate.connect(() => save_iso());
        this.add_action(save_action);

        var quit_action = new GLib.SimpleAction("quit", null);
        quit_action.activate.connect(() => {
            save_settings();
            this.quit();
        });
        this.add_action(quit_action);

        var refresh_action = new GLib.SimpleAction("refresh", null);
        refresh_action.activate.connect(() => {
            refresh_fs_view();
            if (iso_loaded) refresh_iso_view();
        });
        this.add_action(refresh_action);

        var about_action = new GLib.SimpleAction("about", null);
        about_action.activate.connect(() => show_about());
        this.add_action(about_action);

        // Set accelerators
        this.set_accels_for_action("app.new", {"<Control>N"});
        this.set_accels_for_action("app.open", {"<Control>O"});
        this.set_accels_for_action("app.save", {"<Control>S"});
        this.set_accels_for_action("app.quit", {"<Control>Q"});
    }

    private Gtk.Box build_toolbar() {
        var toolbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        toolbar.margin_start = 4;
        toolbar.margin_end = 4;
        toolbar.margin_top = 4;
        toolbar.margin_bottom = 4;

        // New button
        var new_btn = new Gtk.Button.from_icon_name("document-new");
        new_btn.tooltip_text = "New ISO";
        new_btn.clicked.connect(() => new_iso());
        toolbar.append(new_btn);

        // Open button
        var open_btn = new Gtk.Button.from_icon_name("document-open");
        open_btn.tooltip_text = "Open ISO";
        open_btn.clicked.connect(() => open_iso());
        toolbar.append(open_btn);

        // Save button
        var save_btn = new Gtk.Button.from_icon_name("document-save");
        save_btn.tooltip_text = "Save ISO";
        save_btn.clicked.connect(() => save_iso());
        toolbar.append(save_btn);

        toolbar.append(new Gtk.Separator(Gtk.Orientation.VERTICAL));

        // Add button
        var add_btn = new Gtk.Button.from_icon_name("list-add");
        add_btn.tooltip_text = "Add to ISO";
        add_btn.clicked.connect(() => add_to_iso());
        toolbar.append(add_btn);

        // Extract button
        var extract_btn = new Gtk.Button.from_icon_name("extract");
        extract_btn.tooltip_text = "Extract from ISO";
        extract_btn.clicked.connect(() => extract_from_iso());
        toolbar.append(extract_btn);

        // Delete button
        var delete_btn = new Gtk.Button.from_icon_name("edit-delete");
        delete_btn.tooltip_text = "Delete from ISO";
        delete_btn.clicked.connect(() => delete_from_iso());
        toolbar.append(delete_btn);

        return toolbar;
    }

    private Gtk.Box build_fs_browser() {
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        // Path entry with navigation
        var nav_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        var up_btn = new Gtk.Button.from_icon_name("go-up");
        up_btn.clicked.connect(() => fs_go_up());
        nav_box.append(up_btn);

        fs_path_entry = new Gtk.Entry();
        fs_path_entry.hexpand = true;
        fs_path_entry.activate.connect(() => fs_navigate_to(fs_path_entry.text));
        nav_box.append(fs_path_entry);

        var refresh_btn = new Gtk.Button.from_icon_name("view-refresh");
        refresh_btn.clicked.connect(() => refresh_fs_view());
        nav_box.append(refresh_btn);

        box.append(nav_box);

        // File list
        fs_store = new GLib.ListStore(typeof(FileItem));
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var item_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            var icon = new Gtk.Image();
            var label = new Gtk.Label("");
            label.xalign = 0;
            item_box.append(icon);
            item_box.append(label);
            list_item.child = item_box;
        });
        factory.bind.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var file_item = list_item.item as FileItem;
            var item_box = list_item.child as Gtk.Box;
            var icon = item_box.get_first_child() as Gtk.Image;
            var label = icon.get_next_sibling() as Gtk.Label;
            icon.icon_name = file_item.icon_name;
            label.label = file_item.name;
        });

        var selection = new Gtk.SingleSelection(fs_store);
        fs_list_view = new Gtk.ListView(selection, factory);
        fs_list_view.vexpand = true;

        var scrolled = new Gtk.ScrolledWindow();
        scrolled.child = fs_list_view;
        box.append(scrolled);

        // Initialize to home directory
        fs_path_entry.text = Environment.get_home_dir();
        refresh_fs_view();

        return box;
    }

    private Gtk.Box build_iso_browser() {
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        // Path entry with navigation
        var nav_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        var up_btn = new Gtk.Button.from_icon_name("go-up");
        up_btn.clicked.connect(() => iso_go_up());
        nav_box.append(up_btn);

        iso_path_entry = new Gtk.Entry();
        iso_path_entry.hexpand = true;
        iso_path_entry.text = "/";
        nav_box.append(iso_path_entry);

        iso_size_label = new Gtk.Label("");
        nav_box.append(iso_size_label);

        box.append(nav_box);

        // ISO file list
        iso_store = new GLib.ListStore(typeof(FileItem));
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var item_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            var icon = new Gtk.Image();
            var label = new Gtk.Label("");
            label.xalign = 0;
            item_box.append(icon);
            item_box.append(label);
            list_item.child = item_box;
        });
        factory.bind.connect((item) => {
            var list_item = item as Gtk.ListItem;
            var file_item = list_item.item as FileItem;
            var item_box = list_item.child as Gtk.Box;
            var icon = item_box.get_first_child() as Gtk.Image;
            var label = icon.get_next_sibling() as Gtk.Label;
            icon.icon_name = file_item.icon_name;
            label.label = file_item.name;
        });

        var selection = new Gtk.SingleSelection(iso_store);
        iso_list_view = new Gtk.ListView(selection, factory);
        iso_list_view.vexpand = true;

        var scrolled = new Gtk.ScrolledWindow();
        scrolled.child = iso_list_view;
        box.append(scrolled);

        return box;
    }

    // File operations
    private void new_iso() {
        // TODO: Create new ISO
    }

    private void open_iso() {
        var dialog = new Gtk.FileDialog();
        dialog.title = "Open ISO Image";
        var filter = new Gtk.FileFilter();
        filter.add_pattern("*.iso");
        filter.add_pattern("*.nrg");
        filter.add_pattern("*.mdf");
        filter.name = "ISO Images";
        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(filter);
        dialog.filters = filters;

        dialog.open.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.open.end(res);
                if (file != null) {
                    open_iso_file(file.get_path());
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    private void open_iso_file(string path) {
        int result = Bk.open_image(vol_info, path);
        if (result < 0) {
            show_error("Failed to open ISO: %s", Bk.get_error_string(result));
            return;
        }

        result = Bk.read_vol_info(vol_info);
        if (result < 0) {
            show_error("Failed to read volume info: %s", Bk.get_error_string(result));
            return;
        }

        iso_loaded = true;
        iso_path_entry.text = "/";
        refresh_iso_view();

        // Update window title
        string? vol_name = Bk.get_volume_name(vol_info);
        if (vol_name != null && vol_name.length > 0) {
            main_window.title = "ISO Master - %s".printf(vol_name);
        } else {
            main_window.title = "ISO Master - %s".printf(Path.get_basename(path));
        }
    }

    private void save_iso() {
        if (!iso_loaded) {
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = "Save ISO Image";
        var filter = new Gtk.FileFilter();
        filter.add_pattern("*.iso");
        filter.name = "ISO Images";
        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(filter);
        dialog.filters = filters;

        dialog.save.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.save.end(res);
                if (file != null) {
                    int result = Bk.write_image(file.get_path(), vol_info, 0, Bk.FNTYPE_JOLIET, null);
                    if (result < 0) {
                        show_error("Failed to save ISO: %s", Bk.get_error_string(result));
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    private void add_to_iso() {
        // TODO: Add files to ISO
    }

    private void extract_from_iso() {
        // TODO: Extract files from ISO
    }

    private void delete_from_iso() {
        // TODO: Delete files from ISO
    }

    private void refresh_fs_view() {
        fs_store.remove_all();
        var path = fs_path_entry.text;
        if (path.length == 0) {
            path = "/";
        }

        try {
            var dir = Dir.open(path);
            string? name;
            while ((name = dir.read_name()) != null) {
                if (!settings.show_hidden_files && name.has_prefix(".")) {
                    continue;
                }
                var full_path = Path.build_filename(path, name);
                var file_info = File.new_for_path(full_path).query_info("standard::*", 0);
                var item = new FileItem();
                item.name = name;
                item.path = full_path;
                item.is_dir = file_info.get_file_type() == FileType.DIRECTORY;
                item.icon_name = item.is_dir ? "folder" : "text-x-generic";
                item.size = file_info.get_size();
                fs_store.append(item);
            }
        } catch (Error e) {
            // Directory read error
        }
    }

    private void refresh_iso_view() {
        iso_store.remove_all();
        if (!iso_loaded) {
            return;
        }

        // TODO: Read ISO directory contents
    }

    private void fs_go_up() {
        var path = fs_path_entry.text;
        if (path.length > 1) {
            fs_path_entry.text = Path.get_dirname(path);
            refresh_fs_view();
        }
    }

    private void iso_go_up() {
        var path = iso_path_entry.text;
        if (path.length > 1) {
            iso_path_entry.text = Path.get_dirname(path);
            refresh_iso_view();
        }
    }

    private void fs_navigate_to(string path) {
        fs_path_entry.text = path;
        refresh_fs_view();
    }

    private void show_error(string format, ...) {
        var va = va_list();
        var msg = format.vprintf(va);
        var dialog = new Adw.AlertDialog("Error", msg);
        dialog.add_response("ok", "_OK");
        dialog.present(main_window);
    }

    private void show_about() {
        var about = new Adw.AboutDialog();
        about.application_name = "ISO Master";
        about.application_icon = "isomaster";
        about.version = "2.0.0";
        about.developer_name = "Andrew Smith";
        about.website = "http://littlesvr.ca/isomaster/";
        about.license_type = Gtk.License.GPL_2_0;
        about.present(main_window);
    }

    // Settings management
    private string get_settings_path() {
        return Path.build_filename(Environment.get_user_config_dir(), "isomaster", "isomaster.conf");
    }

    private void load_settings() {
        var path = get_settings_path();
        var dict = Ini.load(path);
        if (dict == null) {
            return;
        }

        settings.window_width = Ini.get_int(dict, "window:width", 800);
        settings.window_height = Ini.get_int(dict, "window:height", 600);
        settings.top_pane_height = Ini.get_int(dict, "window:topPaneHeight", 300);
        settings.show_hidden_files = Ini.get_boolean(dict, "browser:showHidden", 0) != 0;
        settings.sort_dirs_first = Ini.get_boolean(dict, "browser:sortDirsFirst", 1) != 0;
        settings.case_sensitive_sort = Ini.get_boolean(dict, "browser:caseSensitiveSort", 0) != 0;

        
    }

    private void save_settings() {
        var dir = Path.get_dirname(get_settings_path());
        DirUtils.create_with_parents(dir, 0755);

        // Update window size
        if (main_window != null) {
            settings.window_width = main_window.get_width();
            settings.window_height = main_window.get_height();
        }

        // Write settings manually
        try {
            var file = FileStream.open(get_settings_path(), "w");
            if (file != null) {
                file.printf("[window]\n");
                file.printf("width = %d\n", settings.window_width);
                file.printf("height = %d\n", settings.window_height);
                file.printf("topPaneHeight = %d\n", settings.top_pane_height);
                file.printf("\n[browser]\n");
                file.printf("showHidden = %d\n", settings.show_hidden_files ? 1 : 0);
                file.printf("sortDirsFirst = %d\n", settings.sort_dirs_first ? 1 : 0);
                file.printf("caseSensitiveSort = %d\n", settings.case_sensitive_sort ? 1 : 0);
            }
        } catch (Error e) {
            // Write error
        }
    }
}

// Entry point
public static int main(string[] args) {
    var app = new IsoMaster();
    return app.run(args);
}
