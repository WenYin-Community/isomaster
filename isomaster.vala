/*
 * ISO Master - GTK4 Vala Implementation
 * Main application and window
 */

// Gettext support
const string GETTEXT_PACKAGE = "isomaster";

// Icon path - use local icons directory for development
const string ICONPATH = "icons";

// Translation helper (use _t to avoid conflict with gi18n-lib.h)
public static string _t(string str) {
    return GLib.dgettext(GETTEXT_PACKAGE, str);
}

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
    // Use Adw.ApplicationWindow for proper Adwaita theming
    private Adw.ApplicationWindow? main_window = null;
    private AppSettings settings;
    private Bk.VolInfo* vol_info = null;
    private bool iso_loaded = false;
    private string current_iso_path = "/";
    private Adw.StyleManager? style_manager = null;

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

        // Initialize style manager (must be after gtk_init)
        style_manager = Adw.StyleManager.get_default();
        
        // Set Adwaita style based on settings
        style_manager.color_scheme = settings.dark_mode 
            ? Adw.ColorScheme.PREFER_DARK 
            : Adw.ColorScheme.PREFER_LIGHT;

        // Create main window with Adwaita
        main_window = new Adw.ApplicationWindow(this);
        main_window.title = _t("ISO Master");
        main_window.default_width = settings.window_width;
        main_window.default_height = settings.window_height;
        main_window.icon_name = "isomaster";

        // Build UI with Adwaita header bar
        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        // Add header bar for title and window controls
        var header_bar = new Adw.HeaderBar();
        header_bar.title_widget = new Adw.WindowTitle(_t("ISO Master"), "");

        // Menu bar
        var menubar = build_menubar();
        this.set_menubar(menubar);

        // Theme toggle button
        var theme_button = new Gtk.Button();
        theme_button.icon_name = style_manager.color_scheme == Adw.ColorScheme.PREFER_DARK 
            ? "weather-clear-symbolic" : "weather-clear-night-symbolic";
        theme_button.tooltip_text = style_manager.color_scheme == Adw.ColorScheme.PREFER_DARK 
            ? _t("Switch to Light Mode") : _t("Switch to Dark Mode");
        theme_button.clicked.connect(() => {
            if (style_manager.color_scheme == Adw.ColorScheme.PREFER_DARK) {
                style_manager.color_scheme = Adw.ColorScheme.PREFER_LIGHT;
                theme_button.icon_name = "weather-clear-night-symbolic";
                theme_button.tooltip_text = _t("Switch to Dark Mode");
                settings.dark_mode = false;
            } else {
                style_manager.color_scheme = Adw.ColorScheme.PREFER_DARK;
                theme_button.icon_name = "weather-clear-symbolic";
                theme_button.tooltip_text = _t("Switch to Light Mode");
                settings.dark_mode = true;
            }
        });
        header_bar.pack_start(theme_button);

        // Add hamburger menu button to header bar
        var menu_button = new Gtk.MenuButton();
        menu_button.icon_name = "open-menu-symbolic";
        menu_button.menu_model = menubar;
        menu_button.tooltip_text = _t("Menu");
        header_bar.pack_end(menu_button);

        main_box.append(header_bar);

        // Content area
        var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_box.append(content_box);

        main_window.set_content(main_box);

        // Toolbar
        var toolbar = build_toolbar();
        content_box.append(toolbar);

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

        content_box.append(paned);

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
        file_menu.append(_t("_New"), "app.new");
        file_menu.append(_t("_Open"), "app.open");
        file_menu.append(_t("_Save"), "app.save");
        file_menu.append(_t("Save _As"), "app.save-as");
        file_menu.append(_t("Create _Directory"), "app.create-dir");
        file_menu.append(_t("_Rename"), "app.rename");
        file_menu.append(_t("_Properties"), "app.properties");
        file_menu.append(_t("_Quit"), "app.quit");
        menubar.append_submenu(_t("_File"), file_menu);

        // Edit menu
        var edit_menu = new GLib.Menu();
        edit_menu.append(_t("_Edit File"), "app.edit-file");
        edit_menu.append(_t("_View File"), "app.view-file");
        edit_menu.append(_t("Change _Permissions"), "app.change-permissions");
        edit_menu.append(_t("_Preferences"), "app.preferences");
        menubar.append_submenu(_t("_Edit"), edit_menu);

        // Tools menu
        var tools_menu = new GLib.Menu();
        tools_menu.append(_t("Boot _Info"), "app.boot-info");
        tools_menu.append(_t("Set _Boot File"), "app.set-boot-file");
        tools_menu.append(_t("Add Boot Record from _File"), "app.add-boot-from-file");
        tools_menu.append(_t("_Extract Boot Record"), "app.extract-boot");
        tools_menu.append(_t("_Delete Boot Record"), "app.delete-boot");
        menubar.append_submenu(_t("_Tools"), tools_menu);

        // View menu
        var view_menu = new GLib.Menu();
        view_menu.append(_t("_Refresh"), "app.refresh");
        view_menu.append(_t("Show _Hidden Files"), "app.show-hidden");
        view_menu.append(_t("Sort _Directories First"), "app.sort-dirs-first");
        view_menu.append(_t("_Case Sensitive Sort"), "app.case-sensitive");
        menubar.append_submenu(_t("_View"), view_menu);

        // Help menu
        var help_menu = new GLib.Menu();
        help_menu.append(_t("_Contents"), "app.help");
        help_menu.append(_t("_About"), "app.about");
        menubar.append_submenu(_t("_Help"), help_menu);

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

        var save_as_action = new GLib.SimpleAction("save-as", null);
        save_as_action.activate.connect(() => save_iso_as());
        this.add_action(save_as_action);

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

        var show_hidden_action = new GLib.SimpleAction("show-hidden", null);
        show_hidden_action.activate.connect(() => {
            settings.show_hidden_files = !settings.show_hidden_files;
            refresh_fs_view();
        });
        this.add_action(show_hidden_action);

        var sort_dirs_action = new GLib.SimpleAction("sort-dirs-first", null);
        sort_dirs_action.activate.connect(() => {
            settings.sort_dirs_first = !settings.sort_dirs_first;
            refresh_fs_view();
            if (iso_loaded) refresh_iso_view();
        });
        this.add_action(sort_dirs_action);

        var case_sensitive_action = new GLib.SimpleAction("case-sensitive", null);
        case_sensitive_action.activate.connect(() => {
            settings.case_sensitive_sort = !settings.case_sensitive_sort;
            refresh_fs_view();
            if (iso_loaded) refresh_iso_view();
        });
        this.add_action(case_sensitive_action);

        var create_dir_action = new GLib.SimpleAction("create-dir", null);
        create_dir_action.activate.connect(() => create_iso_dir());
        this.add_action(create_dir_action);

        var rename_action = new GLib.SimpleAction("rename", null);
        rename_action.activate.connect(() => rename_iso_item());
        this.add_action(rename_action);

        var properties_action = new GLib.SimpleAction("properties", null);
        properties_action.activate.connect(() => show_volume_properties());
        this.add_action(properties_action);

        var edit_file_action = new GLib.SimpleAction("edit-file", null);
        edit_file_action.activate.connect(() => edit_selected_file());
        this.add_action(edit_file_action);

        var view_file_action = new GLib.SimpleAction("view-file", null);
        view_file_action.activate.connect(() => view_selected_file());
        this.add_action(view_file_action);

        var change_perms_action = new GLib.SimpleAction("change-permissions", null);
        change_perms_action.activate.connect(() => change_permissions());
        this.add_action(change_perms_action);

        var preferences_action = new GLib.SimpleAction("preferences", null);
        preferences_action.activate.connect(() => show_preferences());
        this.add_action(preferences_action);

        var boot_info_action = new GLib.SimpleAction("boot-info", null);
        boot_info_action.activate.connect(() => show_boot_info());
        this.add_action(boot_info_action);

        var set_boot_action = new GLib.SimpleAction("set-boot-file", null);
        set_boot_action.activate.connect(() => set_boot_file());
        this.add_action(set_boot_action);

        var add_boot_action = new GLib.SimpleAction("add-boot-from-file", null);
        add_boot_action.activate.connect(() => add_boot_record_from_file());
        this.add_action(add_boot_action);

        var extract_boot_action = new GLib.SimpleAction("extract-boot", null);
        extract_boot_action.activate.connect(() => extract_boot_record());
        this.add_action(extract_boot_action);

        var delete_boot_action = new GLib.SimpleAction("delete-boot", null);
        delete_boot_action.activate.connect(() => delete_boot_record());
        this.add_action(delete_boot_action);

        var help_action = new GLib.SimpleAction("help", null);
        help_action.activate.connect(() => show_help());
        this.add_action(help_action);

        var about_action = new GLib.SimpleAction("about", null);
        about_action.activate.connect(() => show_about());
        this.add_action(about_action);

        // Set accelerators
        this.set_accels_for_action("app.new", {"<Control>N"});
        this.set_accels_for_action("app.open", {"<Control>O"});
        this.set_accels_for_action("app.save", {"<Control>S"});
        this.set_accels_for_action("app.quit", {"<Control>Q"});
        this.set_accels_for_action("app.rename", {"F2"});
        this.set_accels_for_action("app.refresh", {"F5"});
        this.set_accels_for_action("app.edit-file", {"F4"});
        this.set_accels_for_action("app.view-file", {"F3"});
        this.set_accels_for_action("app.help", {"F1"});
    }

    private Gtk.Box build_toolbar() {
        var toolbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        toolbar.margin_start = 4;
        toolbar.margin_end = 4;
        toolbar.margin_top = 4;
        toolbar.margin_bottom = 4;

        // Load icons from ICONPATH
        string icon_path = ICONPATH ?? "/usr/local/share/isomaster/icons";

        // New button
        var new_btn = new Gtk.Button();
        var new_icon = load_icon(icon_path + "/add2-kearone.png", 24);
        new_btn.child = new_icon;
        new_btn.tooltip_text = _t("New ISO");
        new_btn.clicked.connect(() => new_iso());
        toolbar.append(new_btn);

        // Open button
        var open_btn = new Gtk.Button();
        var open_icon = load_icon(icon_path + "/go-back-kearone.png", 24);
        open_btn.child = open_icon;
        open_btn.tooltip_text = _t("Open ISO");
        open_btn.clicked.connect(() => open_iso());
        toolbar.append(open_btn);

        // Save button
        var save_btn = new Gtk.Button();
        var save_icon = load_icon(icon_path + "/add2-kearone.png", 24);
        save_btn.child = save_icon;
        save_btn.tooltip_text = _t("Save ISO");
        save_btn.clicked.connect(() => save_iso());
        toolbar.append(save_btn);

        toolbar.append(new Gtk.Separator(Gtk.Orientation.VERTICAL));

        // Add button
        var add_btn = new Gtk.Button();
        var add_icon = load_icon(icon_path + "/add2-kearone.png", 24);
        add_btn.child = add_icon;
        add_btn.tooltip_text = _t("Add to ISO");
        add_btn.clicked.connect(() => add_to_iso());
        toolbar.append(add_btn);

        // Extract button
        var extract_btn = new Gtk.Button();
        var extract_icon = load_icon(icon_path + "/extract2-kearone.png", 24);
        extract_btn.child = extract_icon;
        extract_btn.tooltip_text = _t("Extract from ISO");
        extract_btn.clicked.connect(() => extract_from_iso());
        toolbar.append(extract_btn);

        // Delete button
        var delete_btn = new Gtk.Button();
        var delete_icon = load_icon(icon_path + "/delete-kearone.png", 24);
        delete_btn.child = delete_icon;
        delete_btn.tooltip_text = _t("Delete from ISO");
        delete_btn.clicked.connect(() => delete_from_iso());
        toolbar.append(delete_btn);

        return toolbar;
    }

    private Gtk.Image load_icon(string path, int size) {
        try {
            var texture = Gdk.Texture.from_filename(path);
            return new Gtk.Image.from_paintable(texture);
        } catch (Error e) {
            // Fallback to missing image icon
            return new Gtk.Image.from_icon_name("image-missing");
        }
    }

    private Gtk.Box build_fs_browser() {
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        string icon_path = ICONPATH ?? "/usr/local/share/isomaster/icons";

        // Path entry with navigation
        var nav_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        var up_btn = new Gtk.Button();
        up_btn.child = load_icon(icon_path + "/go-back-kearone.png", 16);
        up_btn.tooltip_text = _t("Go up");
        up_btn.clicked.connect(() => fs_go_up());
        nav_box.append(up_btn);

        fs_path_entry = new Gtk.Entry();
        fs_path_entry.hexpand = true;
        fs_path_entry.activate.connect(() => fs_navigate_to(fs_path_entry.text));
        nav_box.append(fs_path_entry);

        var refresh_btn = new Gtk.Button.from_icon_name("view-refresh");
        refresh_btn.tooltip_text = _t("Refresh");
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

        // Handle double-click to navigate into directories
        fs_list_view.activate.connect((pos) => {
            var item = fs_store.get_item(pos) as FileItem;
            if (item != null && item.is_dir) {
                fs_navigate_to(item.path);
            }
        });

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
        string icon_path = ICONPATH ?? "/usr/local/share/isomaster/icons";

        // Path entry with navigation
        var nav_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        var up_btn = new Gtk.Button();
        up_btn.child = load_icon(icon_path + "/go-back-kearone.png", 16);
        up_btn.tooltip_text = _t("Go up");
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

        // Handle double-click to navigate into directories
        iso_list_view.activate.connect((pos) => {
            var item = iso_store.get_item(pos) as FileItem;
            if (item != null && item.is_dir) {
                iso_navigate_to(item.path);
            }
        });

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
        dialog.title = _t("Open ISO Image");
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
            show_error(_t("Failed to open ISO: %s"), Bk.get_error_string(result));
            return;
        }

        result = Bk.read_vol_info(vol_info);
        if (result < 0) {
            show_error(_t("Failed to read volume info: %s"), Bk.get_error_string(result));
            return;
        }

        // Read directory tree
        result = Bk.read_dir_tree(vol_info, Bk.FNTYPE_JOLIET, false, null);
        if (result < 0) {
            show_error(_t("Failed to read directory tree: %s"), Bk.get_error_string(result));
            return;
        }

        iso_loaded = true;
        current_iso_path = "/";
        iso_path_entry.text = "/";
        refresh_iso_view();

        // Update window title
        string? vol_name = Bk.get_volume_name(vol_info);
        if (vol_name != null && vol_name.length > 0) {
            main_window.title = "ISO Master - %s".printf(vol_name);
        } else {
            main_window.title = "ISO Master - %s".printf(Path.get_basename(path));
        }

        // Update ISO size
        int64 iso_size = Bk.estimate_iso_size(vol_info, Bk.FNTYPE_JOLIET);
        iso_size_label.label = format_size(iso_size);
    }

    private void save_iso() {
        if (!iso_loaded) {
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = _t("Save ISO Image");
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
                        show_error(_t("Failed to save ISO: %s"), Bk.get_error_string(result));
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    private void add_to_iso() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = _t("Add files to ISO");

        dialog.open.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.open.end(res);
                if (file != null) {
                    int result = Bk.add(vol_info, file.get_path(), current_iso_path, null);
                    if (result < 0) {
                        show_error(_t("Failed to add file: %s"), Bk.get_error_string(result));
                    } else {
                        refresh_iso_view();
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    private void extract_from_iso() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        // Get selected item
        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = _t("Extract to...");
        dialog.initial_file = GLib.File.new_for_path(item.name);

        dialog.save.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.save.end(res);
                if (file != null) {
                    int result = Bk.extract(vol_info, item.path, file.get_path(), false, null);
                    if (result < 0) {
                        show_error(_t("Failed to extract: %s"), Bk.get_error_string(result));
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    private void delete_from_iso() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        // Get selected item
        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null) {
            show_error(_t("No file selected"));
            return;
        }

        // Confirm deletion
        var dialog = new Adw.AlertDialog(
            _t("Confirm Delete"),
            _t("Are you sure you want to delete '%s' from the ISO?").printf(item.name)
        );
        dialog.add_response("cancel", _t("_Cancel"));
        dialog.add_response("delete", _t("_Delete"));
        dialog.response.connect((response) => {
            if (response == "delete") {
                int result = Bk.delete(vol_info, item.path);
                if (result < 0) {
                    show_error(_t("Failed to delete: %s"), Bk.get_error_string(result));
                } else {
                    refresh_iso_view();
                }
            }
        });
        dialog.present(main_window);
    }

    private void create_iso_dir() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        // Show input dialog for directory name
        var dialog = new Adw.AlertDialog(_t("Create Directory"), _t("Enter directory name:"));
        dialog.add_response("cancel", _t("_Cancel"));
        dialog.add_response("create", _t("_Create"));

        var entry = new Gtk.Entry();
        entry.placeholder_text = _t("New directory");
        dialog.extra_child = entry;

        dialog.response.connect((response) => {
            if (response == "create" && entry.text.length > 0) {
                int result = Bk.create_dir(vol_info, current_iso_path, entry.text);
                if (result < 0) {
                    show_error(_t("Failed to create directory: %s"), Bk.get_error_string(result));
                } else {
                    refresh_iso_view();
                }
            }
        });
        dialog.present(main_window);
    }

    private void rename_iso_item() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        // Get selected item
        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null) {
            show_error(_t("No file selected"));
            return;
        }

        // Show input dialog for new name
        var dialog = new Adw.AlertDialog(_t("Rename"), _t("Enter new name:"));
        dialog.add_response("cancel", _t("_Cancel"));
        dialog.add_response("rename", _t("_Rename"));

        var entry = new Gtk.Entry();
        entry.text = item.name;
        dialog.extra_child = entry;

        dialog.response.connect((response) => {
            if (response == "rename" && entry.text.length > 0) {
                string old_path = item.path;
                string new_path = Path.get_dirname(old_path) + "/" + entry.text;
                int result = Bk.rename(vol_info, old_path, new_path);
                if (result < 0) {
                    show_error(_t("Failed to rename: %s"), Bk.get_error_string(result));
                } else {
                    refresh_iso_view();
                }
            }
        });
        dialog.present(main_window);
    }

    private void show_volume_properties() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        string? vol_name = Bk.get_volume_name(vol_info);
        string? publisher = Bk.get_publisher(vol_info);
        int64 iso_size = Bk.estimate_iso_size(vol_info, Bk.FNTYPE_JOLIET);

        var dialog = new Adw.AlertDialog(_t("Volume Properties"), null);
        dialog.body = _t("Volume Name: %s\nPublisher: %s\nEstimated Size: %s").printf(
            vol_name ?? _t("(none)"),
            publisher ?? _t("(none)"),
            format_size(iso_size)
        );
        dialog.add_response("ok", _t("_OK"));

        // Add entry fields for editing
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 12;
        box.margin_bottom = 12;

        var name_label = new Gtk.Label(_t("Volume Name:"));
        name_label.xalign = 0;
        box.append(name_label);

        var name_entry = new Gtk.Entry();
        name_entry.text = vol_name ?? "";
        box.append(name_entry);

        var pub_label = new Gtk.Label(_t("Publisher:"));
        pub_label.xalign = 0;
        box.append(pub_label);

        var pub_entry = new Gtk.Entry();
        pub_entry.text = publisher ?? "";
        box.append(pub_entry);

        dialog.extra_child = box;

        dialog.response.connect((response) => {
            if (response == "ok") {
                // Update volume name
                if (name_entry.text.length > 0) {
                    int result = Bk.set_vol_name(vol_info, name_entry.text);
                    if (result < 0) {
                        show_error(_t("Failed to set volume name: %s"), Bk.get_error_string(result));
                    }
                }
                // Update publisher
                if (pub_entry.text.length > 0) {
                    int result = Bk.set_publisher(vol_info, pub_entry.text);
                    if (result < 0) {
                        show_error(_t("Failed to set publisher: %s"), Bk.get_error_string(result));
                    }
                }
                // Update window title
                main_window.title = "ISO Master - %s".printf(name_entry.text);
            }
        });
        dialog.present(main_window);
    }

    private void set_boot_file() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        // Get selected item
        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null || item.is_dir) {
            show_error("Please select a file (not a directory)");
            return;
        }

        var dialog = new Adw.AlertDialog(
            _t("Set Boot File"),
            _t("Set '%s' as boot file?").printf(item.name)
        );
        dialog.add_response("cancel", _t("_Cancel"));
        dialog.add_response("set", _t("_Set"));

        dialog.response.connect((response) => {
            if (response == "set") {
                int result = Bk.set_boot_file(vol_info, item.path);
                if (result < 0) {
                    show_error(_t("Failed to set boot file: %s"), Bk.get_error_string(result));
                } else {
                    show_error(_t("Boot file set successfully"));
                }
            }
        });
        dialog.present(main_window);
    }

    private void extract_boot_record() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = _t("Extract Boot Record to...");
        dialog.initial_file = GLib.File.new_for_path("boot.img");

        dialog.save.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.save.end(res);
                if (file != null) {
                    int result = Bk.extract_boot_record(vol_info, file.get_path(), 0644);
                    if (result < 0) {
                        show_error("Failed to extract boot record: %s", Bk.get_error_string(result));
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    private void delete_boot_record() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var dialog = new Adw.AlertDialog(
            _t("Delete Boot Record"),
            _t("Are you sure you want to delete the boot record?")
        );
        dialog.add_response("cancel", _t("_Cancel"));
        dialog.add_response("delete", _t("_Delete"));

        dialog.response.connect((response) => {
            if (response == "delete") {
                Bk.delete_boot_record(vol_info);
            }
        });
        dialog.present(main_window);
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

        // Get current directory from ISO
        Bk.BkDir* dir = null;
        int result = Bk.get_dir_from_string(vol_info, current_iso_path, out dir);
        if (result < 0 || dir == null) {
            return;
        }

        // Iterate through children
        Bk.BkFileBase* child = dir->children;
        while (child != null) {
            string name = (string) child->name;
            bool is_dir = Bk.S_ISDIR(child->posixFileMode);
            bool is_file = Bk.S_ISREG(child->posixFileMode);

            var item = new FileItem();
            item.name = name;
            item.path = current_iso_path + (current_iso_path.has_suffix("/") ? "" : "/") + name;
            item.is_dir = is_dir;
            item.icon_name = is_dir ? "folder" : "text-x-generic";

            if (is_file) {
                // Get file size from BkFile
                Bk.BkFile* file = (Bk.BkFile*) child;
                item.size = file->size;
            } else {
                item.size = 0;
            }

            iso_store.append(item);
            child = child->next;
        }
    }

    private void fs_go_up() {
        var path = fs_path_entry.text;
        if (path.length > 1) {
            fs_path_entry.text = Path.get_dirname(path);
            refresh_fs_view();
        }
    }

    private void iso_go_up() {
        if (current_iso_path.length > 1) {
            current_iso_path = Path.get_dirname(current_iso_path);
            iso_path_entry.text = current_iso_path;
            refresh_iso_view();
        }
    }

    private void iso_navigate_to(string path) {
        current_iso_path = path;
        iso_path_entry.text = path;
        refresh_iso_view();
    }

    private string format_size(int64 size) {
        if (size > 1073741824) {
            return "%.1f GB".printf((double)size / 1073741824);
        } else if (size > 1048576) {
            return "%.1f MB".printf((double)size / 1048576);
        } else if (size > 1024) {
            return "%.1f KB".printf((double)size / 1024);
        } else {
            return size.to_string() + " B";
        }
    }

    private void fs_navigate_to(string path) {
        fs_path_entry.text = path;
        refresh_fs_view();
    }

    private void show_error(string format, ...) {
        var va = va_list();
        var msg = format.vprintf(va);
        var dialog = new Adw.AlertDialog(_t("Error"), msg);
        dialog.add_response("ok", _t("_OK"));
        dialog.present(main_window);
    }

    // Save As functionality
    private void save_iso_as() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = _t("Save ISO Image");
        var filter = new Gtk.FileFilter();
        filter.add_pattern("*.iso");
        filter.name = _t("ISO Images");
        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(filter);
        dialog.filters = filters;

        dialog.save.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.save.end(res);
                if (file != null) {
                    int result = Bk.write_image(file.get_path(), vol_info, 0, Bk.FNTYPE_JOLIET, null);
                    if (result < 0) {
                        show_error(_t("Failed to save ISO: %s"), Bk.get_error_string(result));
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    // Edit selected file (extract, open in editor, re-add)
    private void edit_selected_file() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null || item.is_dir) {
            show_error(_t("Please select a file"));
            return;
        }

        // Extract to temp file
        string temp_path = Path.build_filename(Environment.get_tmp_dir(), item.name);
        int result = Bk.extract(vol_info, item.path, temp_path, false, null);
        if (result < 0) {
            show_error(_t("Failed to extract: %s"), Bk.get_error_string(result));
            return;
        }

        // Open in external editor
        string editor = settings.editor ?? "xdg-open";
        try {
            Process.spawn_command_line_async("%s %s".printf(editor, temp_path));
        } catch (Error e) {
            show_error(_t("Failed to open editor: %s"), e.message);
        }
    }

    // View selected file (extract, open in viewer)
    private void view_selected_file() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null || item.is_dir) {
            show_error(_t("Please select a file"));
            return;
        }

        // Extract to temp file
        string temp_path = Path.build_filename(Environment.get_tmp_dir(), item.name);
        int result = Bk.extract(vol_info, item.path, temp_path, false, null);
        if (result < 0) {
            show_error(_t("Failed to extract: %s"), Bk.get_error_string(result));
            return;
        }

        // Open in external viewer
        string viewer = settings.viewer ?? "xdg-open";
        try {
            Process.spawn_command_line_async("%s %s".printf(viewer, temp_path));
        } catch (Error e) {
            show_error(_t("Failed to open viewer: %s"), e.message);
        }
    }

    // Change permissions of selected ISO item
    private void change_permissions() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var selection = iso_list_view.model as Gtk.SingleSelection;
        if (selection == null || selection.selected_item == null) {
            show_error(_t("No file selected"));
            return;
        }

        var item = selection.selected_item as FileItem;
        if (item == null) {
            show_error(_t("No file selected"));
            return;
        }

        // Show permissions dialog
        var dialog = new Adw.AlertDialog(_t("Change Permissions"), item.name);
        dialog.add_response("cancel", _t("_Cancel"));
        dialog.add_response("apply", _t("_Apply"));

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 12;
        box.margin_bottom = 12;

        // Owner permissions
        var owner_label = new Gtk.Label(_t("Owner:"));
        owner_label.xalign = 0;
        box.append(owner_label);

        var owner_read = new Gtk.CheckButton.with_label(_t("Read"));
        owner_read.active = true;
        box.append(owner_read);

        var owner_write = new Gtk.CheckButton.with_label(_t("Write"));
        owner_write.active = true;
        box.append(owner_write);

        var owner_exec = new Gtk.CheckButton.with_label(_t("Execute"));
        owner_exec.active = false;
        box.append(owner_exec);

        // Group permissions
        var group_label = new Gtk.Label(_t("Group:"));
        group_label.xalign = 0;
        box.append(group_label);

        var group_read = new Gtk.CheckButton.with_label(_t("Read"));
        group_read.active = true;
        box.append(group_read);

        var group_write = new Gtk.CheckButton.with_label(_t("Write"));
        group_write.active = false;
        box.append(group_write);

        var group_exec = new Gtk.CheckButton.with_label(_t("Execute"));
        group_exec.active = false;
        box.append(group_exec);

        // Other permissions
        var other_label = new Gtk.Label(_t("Other:"));
        other_label.xalign = 0;
        box.append(other_label);

        var other_read = new Gtk.CheckButton.with_label(_t("Read"));
        other_read.active = true;
        box.append(other_read);

        var other_write = new Gtk.CheckButton.with_label(_t("Write"));
        other_write.active = false;
        box.append(other_write);

        var other_exec = new Gtk.CheckButton.with_label(_t("Execute"));
        other_exec.active = false;
        box.append(other_exec);

        dialog.extra_child = box;

        dialog.response.connect((response) => {
            if (response == "apply") {
                // Calculate permissions
                uint perms = 0;
                if (owner_read.active) perms |= 0400;
                if (owner_write.active) perms |= 0200;
                if (owner_exec.active) perms |= 0100;
                if (group_read.active) perms |= 0040;
                if (group_write.active) perms |= 0020;
                if (group_exec.active) perms |= 0010;
                if (other_read.active) perms |= 0004;
                if (other_write.active) perms |= 0002;
                if (other_exec.active) perms |= 0001;

                // TODO: Call bk_set_permissions when available
                show_error(_t("Permissions set to %o"), perms);
            }
        });
        dialog.present(main_window);
    }

    // Show preferences window
    private void show_preferences() {
        var dialog = new Adw.AlertDialog(_t("Preferences"), null);
        dialog.add_response("ok", _t("_OK"));

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 12;
        box.margin_bottom = 12;

        // Temp directory
        var temp_label = new Gtk.Label(_t("Temporary directory:"));
        temp_label.xalign = 0;
        box.append(temp_label);

        var temp_entry = new Gtk.Entry();
        temp_entry.text = settings.temp_dir ?? "/tmp";
        box.append(temp_entry);

        // Editor
        var editor_label = new Gtk.Label(_t("Editor:"));
        editor_label.xalign = 0;
        box.append(editor_label);

        var editor_entry = new Gtk.Entry();
        editor_entry.text = settings.editor ?? "leafpad";
        box.append(editor_entry);

        // Viewer
        var viewer_label = new Gtk.Label(_t("Viewer:"));
        viewer_label.xalign = 0;
        box.append(viewer_label);

        var viewer_entry = new Gtk.Entry();
        viewer_entry.text = settings.viewer ?? "firefox";
        box.append(viewer_entry);

        dialog.extra_child = box;

        dialog.response.connect((response) => {
            if (response == "ok") {
                settings.temp_dir = temp_entry.text;
                settings.editor = editor_entry.text;
                settings.viewer = viewer_entry.text;
            }
        });
        dialog.present(main_window);
    }

    // Show boot info
    private void show_boot_info() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        // TODO: Get actual boot info from bk library
        var dialog = new Adw.AlertDialog(_t("Boot Information"), null);
        dialog.body = _t("Boot record information will be displayed here.");
        dialog.add_response("ok", _t("_OK"));
        dialog.present(main_window);
    }

    // Add boot record from file
    private void add_boot_record_from_file() {
        if (!iso_loaded) {
            show_error(_t("No ISO image loaded"));
            return;
        }

        var dialog = new Gtk.FileDialog();
        dialog.title = _t("Select Boot Record File");

        dialog.open.begin(main_window, null, (obj, res) => {
            try {
                var file = dialog.open.end(res);
                if (file != null) {
                    int result = Bk.add_boot_record(vol_info, file.get_path(), Bk.BOOT_MEDIA_NO_EMULATION);
                    if (result < 0) {
                        show_error(_t("Failed to add boot record: %s"), Bk.get_error_string(result));
                    } else {
                        show_error(_t("Boot record added successfully"));
                    }
                }
            } catch (Error e) {
                // User cancelled
            }
        });
    }

    // Show help window
    private void show_help() {
        var dialog = new Adw.AlertDialog(_t("ISO Master Help"), null);
        dialog.body = _t("ISO Master is a graphical CD image editor.") + "\n\n" +
            _t("Keyboard shortcuts:") + "\n" +
            "  Ctrl+N: " + _t("New ISO") + "\n" +
            "  Ctrl+O: " + _t("Open ISO") + "\n" +
            "  Ctrl+S: " + _t("Save ISO") + "\n" +
            "  Ctrl+Q: " + _t("Quit") + "\n" +
            "  F1: " + _t("Help") + "\n" +
            "  F2: " + _t("Rename") + "\n" +
            "  F3: " + _t("View file") + "\n" +
            "  F4: " + _t("Edit file") + "\n" +
            "  F5: " + _t("Refresh") + "\n" +
            "  Delete: " + _t("Delete selected");
        dialog.add_response("ok", _t("_OK"));
        dialog.present(main_window);
    }

    private void show_about() {
        var about = new Adw.AboutDialog();
        about.application_name = _t("ISO Master");
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
        settings.dark_mode = Ini.get_boolean(dict, "ui:darkMode", 0) != 0;
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
                file.printf("\n[ui]\n");
                file.printf("darkMode = %d\n", settings.dark_mode ? 1 : 0);
            }
        } catch (Error e) {
            // Write error
        }
    }
}

// Entry point
public static int main(string[] args) {
    // Initialize gettext
    GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
    GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, GLib.Environment.get_user_data_dir() + "/locale");
    GLib.Intl.bindtextdomain(GETTEXT_PACKAGE, "/usr/share/locale");
    GLib.Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    GLib.Intl.textdomain(GETTEXT_PACKAGE);

    var app = new IsoMaster();
    return app.run(args);
}
