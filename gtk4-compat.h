/*
 * GTK4 Compatibility Layer for ISO Master
 *
 * Provides macros and wrapper functions to ease the GTK2 → GTK4 migration.
 * This file should be included AFTER <gtk/gtk.h> and BEFORE other project headers.
 *
 * Usage: #include "gtk4-compat.h" in each .c file that uses GTK2 APIs.
 *
 * This is a TRANSITIONAL layer. Once migration is complete, these should
 * be replaced with proper GTK4 native code.
 */

#ifndef GTK4_COMPAT_H
#define GTK4_COMPAT_H

#include <gtk/gtk.h>

/* ===== Widget visibility ===== */
/* In GTK4, widgets are visible by default. gtk_widget_show() is a no-op. */
#define gtk_widget_show(w)          /* no-op */
#define gtk_widget_show_all(w)      /* no-op */
#define gtk_widget_hide(w)          gtk_widget_set_visible(w, FALSE)

/* ===== Box constructors ===== */
#define gtk_vbox_new(homogeneous, spacing) \
    gtk_box_new(GTK_ORIENTATION_VERTICAL, spacing)
#define gtk_hbox_new(homogeneous, spacing) \
    gtk_box_new(GTK_ORIENTATION_HORIZONTAL, spacing)

/* ===== Paned constructors ===== */
#define gtk_vpaned_new() \
    gtk_paned_new(GTK_ORIENTATION_VERTICAL)
#define gtk_hpaned_new() \
    gtk_paned_new(GTK_ORIENTATION_HORIZONTAL)

/* ===== Paned packing ===== */
#define gtk_paned_pack1(paned, child, resize, shrink) do { \
    gtk_paned_set_start_child(GTK_PANED(paned), child); \
    gtk_paned_set_resize_start_child(GTK_PANED(paned), resize); \
    gtk_paned_set_shrink_start_child(GTK_PANED(paned), !(shrink)); \
} while(0)

#define gtk_paned_pack2(paned, child, resize, shrink) do { \
    gtk_paned_set_end_child(GTK_PANED(paned), child); \
    gtk_paned_set_resize_end_child(GTK_PANED(paned), resize); \
    gtk_paned_set_shrink_end_child(GTK_PANED(paned), !(shrink)); \
} while(0)

/* ===== Box packing (compat function) ===== */
/* gtk_box_pack_start(box, child, expand, fill, padding) → gtk_box_append */
static inline void gtk_box_pack_start_compat(GtkBox *box, GtkWidget *child,
                                              gboolean expand, gboolean fill,
                                              guint padding)
{
    if (expand) {
        gtk_widget_set_hexpand(child, TRUE);
        gtk_widget_set_vexpand(child, TRUE);
    }
    gtk_box_append(box, child);
}

/* Use compat version */
#undef gtk_box_pack_start
#define gtk_box_pack_start(box, child, expand, fill, padding) \
    gtk_box_pack_start_compat(GTK_BOX(box), GTK_WIDGET(child), expand, fill, padding)

/* ===== Container operations ===== */
/* gtk_container_add → gtk_window_set_child or gtk_box_append depending on parent */
/* We provide a compat macro that tries to handle the most common case */
#define gtk_container_add(parent, child) \
    _gtk4_compat_container_add(GTK_WIDGET(parent), GTK_WIDGET(child))

static inline void _gtk4_compat_container_add(GtkWidget *parent, GtkWidget *child)
{
    if (GTK_IS_WINDOW(parent))
        gtk_window_set_child(GTK_WINDOW(parent), child);
    else if (GTK_IS_FRAME(parent))
        gtk_frame_set_child(GTK_FRAME(parent), child);
    else if (GTK_IS_BOX(parent))
        gtk_box_append(GTK_BOX(parent), child);
    else if (GTK_IS_SCROLLED_WINDOW(parent))
        gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(parent), child);
    else if (GTK_IS_DIALOG(parent)) {
        GtkWidget *content = gtk_dialog_get_content_area(GTK_DIALOG(parent));
        gtk_box_append(GTK_BOX(content), child);
    }
}

#define GTK_CONTAINER(w) (w)

/* ===== Frame shadow type (removed in GTK4, use CSS) ===== */
#define gtk_frame_set_shadow_type(frame, shadow) /* no-op */

/* ===== Stock items → text labels ===== */
#define GTK_STOCK_OK        _("_OK")
#define GTK_STOCK_CANCEL    _("_Cancel")
#define GTK_STOCK_YES       _("_Yes")
#define GTK_STOCK_NO        _("_No")
#define GTK_STOCK_OPEN      _("_Open")
#define GTK_STOCK_SAVE      _("_Save")
#define GTK_STOCK_SAVE_AS   _("Save _As")
#define GTK_STOCK_NEW       _("_New")
#define GTK_STOCK_DELETE    _("_Delete")
#define GTK_STOCK_QUIT      _("_Quit")
#define GTK_STOCK_REFRESH   _("_Refresh")
#define GTK_STOCK_PROPERTIES _("_Properties")
#define GTK_STOCK_HELP      _("_Help")
#define GTK_STOCK_ABOUT     _("_About")
#define GTK_STOCK_ADD       _("_Add")
#define GTK_STOCK_PREFERENCES _("_Preferences")
#define GTK_STOCK_MISSING_IMAGE "image-missing"

/* ===== GtkMenuItem → GSimpleAction callbacks ===== */
/* GTK2 callback signature: void callback(GtkMenuItem *item, gpointer data) */
/* GTK4 callback signature: void callback(GSimpleAction *action, GVariant *param, gpointer data) */
/* For transitional purposes, we redefine GtkMenuItem as GtkWidget */
#define GtkMenuItem GtkWidget

/* ===== Event types (unified in GTK4) ===== */
#define GdkEventButton GdkEvent
#define GdkEventKey    GdkEvent

/* ===== Entry operations ===== */
/* gtk_entry_get_text → gtk_editable_get_text (GTK4) */
#define gtk_entry_get_text(entry) \
    gtk_editable_get_text(GTK_EDITABLE(entry))

/* gtk_entry_set_width_chars exists in GTK4 but may not be declared
 * if using older headers; use gtk_editable_set_width_chars as fallback */
#ifndef gtk_entry_set_width_chars
#define gtk_entry_set_width_chars(entry, n) \
    gtk_editable_set_width_chars(GTK_EDITABLE(entry), n)
#endif

/* ===== Dialog content area ===== */
/* GTK_DIALOG(dialog)->vbox → gtk_dialog_get_content_area(dialog) */

/* ===== gtk_widget_destroy → gtk_window_destroy for dialogs ===== */
#define gtk_widget_destroy(w) \
    (GTK_IS_WINDOW(w) ? gtk_window_destroy(GTK_WINDOW(w)) : \
     GTK_IS_DIALOG(w) ? gtk_window_destroy(GTK_WINDOW(w)) : \
     (void)0)

/* ===== Image from stock → image from icon name ===== */
#define gtk_image_new_from_stock(icon_name, size) \
    gtk_image_new_from_icon_name(icon_name)

/* ===== GTK_STOCK_* for images ===== */
/* Already handled above as text labels; for image contexts use icon names */

/* ===== GtkSeparatorMenuItem ===== */
/* Removed in GTK4. In GMenu-based menus, separators are handled by the menu model.
 * For GtkPopoverMenu, separators are automatic.
 * This macro creates a simple label as placeholder if needed. */
#define gtk_separator_menu_item_new() gtk_label_new("")

/* ===== GtkCheckMenuItem ===== */
/* Removed in GTK4 menus (GMenu model uses stateful actions instead).
 * This transitional typedef keeps code compiling. */
#define GtkCheckMenuItem GtkWidget

/* ===== GtkImageMenuItem ===== */
/* Removed in GTK4. Use regular GtkMenuItem or GMenu items. */
#define GtkImageMenuItem GtkWidget
#define gtk_image_menu_item_new_from_stock(stock, accel) gtk_button_new_with_label(stock)
#define gtk_image_menu_item_new_with_label(label) gtk_button_new_with_label(label)
#define gtk_image_menu_item_new_with_mnemonic(label) gtk_button_new_with_label(label)
#define gtk_image_menu_item_set_image(item, image) /* no-op */

/* ===== GtkToolbar ===== */
/* Removed in GTK4. This is a stub that creates a box. */
#define GtkToolbar GtkWidget
#define gtk_toolbar_new() gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4)
#define gtk_toolbar_append_item(toolbar, text, tooltip, private_data, icon, callback, user_data) \
    ({ GtkWidget *_btn = gtk_button_new(); \
       if (icon) gtk_button_set_child(GTK_BUTTON(_btn), GTK_WIDGET(icon)); \
       gtk_widget_set_tooltip_text(_btn, tooltip); \
       g_signal_connect(_btn, "clicked", G_CALLBACK(callback), user_data); \
       gtk_box_append(GTK_BOX(toolbar), _btn); \
       _btn; })
#define GTK_TOOLBAR(w) (w)
#define gtk_toolbar_append_element(toolbar, type, widget, tooltip, private_data, icon, callback, user_data, size) \
    ({ gtk_box_append(GTK_BOX(toolbar), GTK_WIDGET(widget)); widget; })
#define GTK_TOOLBAR_CHILD_WIDGET 0

/* ===== GtkBin (removed in GTK4) ===== */
#define GTK_BIN(w) (w)
#define gtk_bin_get_child(bin) gtk_widget_get_first_child(GTK_WIDGET(bin))

/* ===== GtkMenuShell ===== */
#define GTK_MENU_SHELL(w) (w)

/* ===== GtkCheckMenuItem cast ===== */
#define GTK_CHECK_MENU_ITEM(w) GTK_CHECK_BUTTON(w)

/* ===== Icon size ===== */
#define GTK_ICON_SIZE_LARGE_TOOLBAR 24
#define gtk_icon_size_lookup(size, width, height) do { *(width) = (size); *(height) = (size); } while(0)

/* ===== Scrolled window (GTK4 takes no args, use set_child after) ===== */
#define gtk_scrolled_window_new(hadj, vadj) \
    gtk_scrolled_window_new()

/* ===== Icon stock names (removed in GTK4) ===== */
#define GTK_STOCK_DIRECTORY "folder"
#define GTK_STOCK_FILE      "text-x-generic"
#define GTK_STOCK_OPEN      "document-open"

/* ===== GtkIconSet / GtkIconFactory (removed in GTK4) ===== */
/* Use GtkIconTheme instead. These stubs handle the common pattern. */
#define GtkIconSet void
#define gtk_icon_factory_lookup_default(stock_id) NULL
#define gtk_icon_set_get_sizes(set, sizes, n_sizes) do { *(n_sizes) = 0; } while(0)

/* ===== gtk_widget_render_icon (removed in GTK4) ===== */
/* Fallback to loading from file directly */
static inline GdkPixbuf* _gtk4_compat_render_icon(GtkWidget *widget, const char *stock_id, int size, const char *detail)
{
    return NULL; /* Will trigger fallback in calling code */
}
#define gtk_widget_render_icon(widget, stock_id, size, detail) \
    _gtk4_compat_render_icon(widget, stock_id, size, detail)

/* ===== gtk_entry_set_text (exists as gtk_editable_set_text in GTK4) ===== */
#define gtk_entry_set_text(entry, text) \
    gtk_editable_set_text(GTK_EDITABLE(entry), text)

/* ===== GdkEvent access (GTK4 uses accessor functions) ===== */
/* In GTK4, GdkEvent is opaque. Use gdk_event_get_* functions.
 * For event->button.x/y, use gdk_event_get_position.
 * For event->button.button, use gdk_button_event_get_button.
 * For event->key.keyval, use gdk_key_event_get_keyval. */

/* ===== gtk_menu_popup (removed in GTK4) ===== */
/* This is a stub. Real implementation needs GtkPopoverMenu. */
#define gtk_menu_popup(menu, parent_menu_shell, parent_menu_item, func, data, button, activate_time) \
    do { /* no-op, needs GtkPopoverMenu migration */ } while(0)

/* ===== GTK_MENU cast ===== */
#define GTK_MENU(w) (w)

/* ===== Event loop (gtk_events_pending/gtk_main_iteration removed) ===== */
#define gtk_events_pending() g_main_context_pending(NULL)
#define gtk_main_iteration() g_main_context_iteration(NULL, TRUE)

/* ===== Dialog separator (removed in GTK4) ===== */
#define gtk_dialog_set_has_separator(dialog, has_separator) /* no-op */

/* ===== GTK_TABLE cast ===== */
#define GTK_TABLE(w) (w)

/* ===== More stock icons ===== */
#define GTK_STOCK_GO_BACK  "go-previous"
#define GTK_STOCK_CLOSE    "window-close"

/* ===== GDK key name fix ===== */
#define GDK_Delete GDK_KEY_Delete
#define GDK_Escape GDK_KEY_Escape

/* ===== GtkWindow constructor ===== */
#define GTK_WINDOW_TOPLEVEL 0
#define gtk_window_new(type) gtk_window_new()

/* ===== GtkFileChooser API changes ===== */
/* These wrappers convert GTK2 char*-based FileChooser API to GTK4 GFile*-based API.
 * We use function pointers to call the real GTK4 functions, bypassing our macros. */

/* Helper: get real GTK4 function for set_current_folder */
typedef gboolean (*_gtk4_set_current_folder_fn)(GtkFileChooser*, GFile*, GError**);
static inline gboolean _gtk4_compat_set_current_folder(GtkFileChooser *chooser, const char *filename)
{
    _gtk4_set_current_folder_fn real_fn = (_gtk4_set_current_folder_fn)gtk_file_chooser_set_current_folder;
    GFile *file = g_file_new_for_path(filename);
    gboolean result = real_fn(chooser, file, NULL);
    g_object_unref(file);
    return result;
}

static inline char* _gtk4_compat_get_current_folder(GtkFileChooser *chooser)
{
    GFile *file = gtk_file_chooser_get_current_folder(chooser);
    if (file) {
        char *path = g_file_get_path(file);
        g_object_unref(file);
        return path;
    }
    return NULL;
}

static inline gboolean _gtk4_compat_set_filename(GtkFileChooser *chooser, const char *filename)
{
    _gtk4_set_current_folder_fn real_fn = (_gtk4_set_current_folder_fn)gtk_file_chooser_set_current_folder;
    GFile *file = g_file_new_for_path(filename);
    gboolean result = real_fn(chooser, file, NULL);
    g_object_unref(file);
    return result;
}

static inline gboolean _gtk4_compat_add_shortcut_folder(GtkFileChooser *chooser, const char *folder, GError **error)
{
    GFile *file = g_file_new_for_path(folder);
    gboolean result = gtk_file_chooser_add_shortcut_folder(chooser, file, error);
    g_object_unref(file);
    return result;
}

/* gtk_file_chooser_get_filename → gtk_file_chooser_get_file (returns GFile*) */
#define gtk_file_chooser_get_filename(chooser) \
    g_file_get_path(gtk_file_chooser_get_file(chooser))

/* Redirect old GTK2 char*-based API to wrappers */
#define gtk_file_chooser_set_current_folder(chooser, filename) \
    _gtk4_compat_set_current_folder(GTK_FILE_CHOOSER(chooser), filename)
#define gtk_file_chooser_get_current_folder(chooser) \
    _gtk4_compat_get_current_folder(GTK_FILE_CHOOSER(chooser))
#define gtk_file_chooser_set_filename(chooser, filename) \
    _gtk4_compat_set_filename(GTK_FILE_CHOOSER(chooser), filename)
#define gtk_file_chooser_add_shortcut_folder(chooser, folder, error) \
    _gtk4_compat_add_shortcut_folder(GTK_FILE_CHOOSER(chooser), folder, error)

/* gtk_file_chooser_set_extra_widget removed, use set_choice or custom header */
#define gtk_file_chooser_set_extra_widget(chooser, widget) /* no-op */

/* ===== gtk_entry_new_with_max_length (removed in GTK4) ===== */
static inline GtkWidget* _gtk4_compat_entry_new_with_max_length(gint max_length)
{
    GtkWidget *entry = gtk_entry_new();
    gtk_entry_set_max_length(GTK_ENTRY(entry), max_length);
    return entry;
}
#define gtk_entry_new_with_max_length(max) \
    _gtk4_compat_entry_new_with_max_length(max)

/* ===== GtkMenuBar / GtkMenu ===== */
/* These are removed in GTK4. In the migrated code, menus use GMenu + GtkPopoverMenuBar.
 * These stubs are for any remaining code paths. */
#define GtkMenuBar        GtkWidget
#define GtkMenu           GtkWidget
#define GtkMenuShell      GtkWidget
#define gtk_menu_bar_new() gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0)
#define gtk_menu_new()     gtk_box_new(GTK_ORIENTATION_VERTICAL, 0)
#define gtk_menu_shell_append(menu, item) gtk_box_append(GTK_BOX(menu), item)
#define gtk_menu_item_set_submenu(item, submenu) /* no-op */
#define gtk_menu_set_accel_group(menu, accel)    /* no-op */

/* ===== GtkAccelGroup ===== */
/* Removed in GTK4. Use GAction + gtk_application_set_accels_for_action. */
#define GtkAccelGroup      GObject
#define gtk_accel_group_new() g_object_new(G_TYPE_OBJECT, NULL)
#define gtk_window_add_accel_group(window, group) /* no-op */
#define gtk_accel_group_connect(group, key, mod, flags, closure) /* no-op */
#define gtk_accel_map_add_entry(path, key, mod) /* no-op */
#define GTK_ACCEL_VISIBLE 0

/* ===== GtkMenuItem operations ===== */
#define gtk_menu_item_new_with_mnemonic(label) gtk_button_new_with_label(label)
#define gtk_menu_item_new_with_label(label) gtk_button_new_with_label(label)
#define gtk_menu_item_set_accel_path(item, path) /* no-op */
#define gtk_menu_item_set_submenu(item, submenu) /* no-op */

/* ===== GtkCheckMenuItem operations ===== */
#define gtk_check_menu_item_new_with_mnemonic(label) gtk_check_button_new_with_mnemonic(label)
#define gtk_check_menu_item_set_active(item, active) gtk_check_button_set_active(GTK_CHECK_BUTTON(item), active)
#define gtk_check_menu_item_get_active(item) gtk_check_button_get_active(GTK_CHECK_BUTTON(item))

/* ===== GtkMisc alignment ===== */
#define gtk_misc_set_alignment(misc, xalign, yalign) \
    gtk_widget_set_halign(GTK_WIDGET(misc), (xalign) < 0.33 ? GTK_ALIGN_START : (xalign) > 0.66 ? GTK_ALIGN_END : GTK_ALIGN_CENTER)

/* ===== gtk_dialog_run (blocking) ===== */
/* This is the biggest removal in GTK4. We provide a compatibility function
 * that uses a local GMainLoop to achieve blocking behavior.
 * This should be replaced with async callbacks in the final migration. */

/* Callback for the response signal in blocking dialog compat */
static void _gtk4_compat_dialog_response(GtkDialog *dialog, gint response_id, gpointer user_data)
{
    gint *result = (gint *)user_data;
    *result = response_id;
    GMainLoop *loop = g_object_get_data(G_OBJECT(dialog), "compat-loop");
    if (loop)
        g_main_loop_quit(loop);
}

static inline gint gtk_dialog_run(GtkDialog *dialog)
{
    GMainLoop *loop;
    gint response = GTK_RESPONSE_NONE;

    g_return_val_if_fail(GTK_IS_DIALOG(dialog), GTK_RESPONSE_NONE);

    loop = g_main_loop_new(NULL, FALSE);
    g_object_set_data(G_OBJECT(dialog), "compat-loop", loop);
    g_signal_connect(dialog, "response", G_CALLBACK(_gtk4_compat_dialog_response), &response);
    gtk_widget_set_visible(GTK_WIDGET(dialog), TRUE);
    g_main_loop_run(loop);
    g_main_loop_unref(loop);

    return response;
}

/* ===== GtkFileChooserButton ===== */
/* Removed in GTK4. Use GtkButton + GtkFileDialog. */
#define GtkFileChooserButton GtkWidget

/* ===== GtkTable → GtkGrid ===== */
#define GtkTable             GtkWidget
#define gtk_table_new(rows, cols, homogeneous) \
    gtk_grid_new()
#define gtk_table_attach_defaults(table, child, left, right, top, bottom) \
    gtk_grid_attach(GTK_GRID(table), child, left, top, (right)-(left), (bottom)-(top))
#define gtk_table_set_row_spacings(table, spacing) \
    gtk_grid_set_row_spacing(GTK_GRID(table), spacing)
#define gtk_table_set_col_spacings(table, spacing) \
    gtk_grid_set_column_spacing(GTK_GRID(table), spacing)

/* ===== GTK_MISC cast (removed in GTK4) ===== */
#define GTK_MISC(w) (w)

/* ===== GtkFileChooserButton (removed in GTK4) ===== */
/* Use a GtkButton + GtkFileChooserDialog instead */
#define gtk_file_chooser_button_new(title, action) \
    gtk_button_new_with_label(title)

/* ===== gtk_window_get_size (removed in GTK4) ===== */
#define gtk_window_get_size(window, width, height) do { \
    if (width) gtk_window_get_default_size(GTK_WINDOW(window), width, NULL); \
    if (height) gtk_window_get_default_size(GTK_WINDOW(window), NULL, height); \
} while(0)

/* ===== GDK key symbols (still available in GTK4) ===== */
/* gdkkeysyms.h was renamed to gdkkeysyms-compat.h in some versions,
 * but the symbols themselves are still available via gdk/gdkkeysyms.h */

/* ===== GtkTreeView signal compat ===== */
/* row-activated → still available in GTK4 GtkTreeView */

/* ===== GtkDialog button text for message dialogs ===== */
/* GTK4 GtkMessageDialog uses text, not stock IDs */
#define GTK_BUTTONS_OK_CANCEL GTK_BUTTONS_OK_CANCEL  /* still exists */
#define GTK_BUTTONS_YES_NO    GTK_BUTTONS_YES_NO     /* still exists */

/* ===== GtkWindow icon ===== */
/* gtk_window_set_icon removed in GTK4, use icon-name property */
#define gtk_window_set_icon(window, pixbuf) \
    gtk_window_set_icon_name(window, "isomaster")

#endif /* GTK4_COMPAT_H */
