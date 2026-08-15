/*
 * ISO Master - small stateless helpers
 */

// Human-readable size string (uses the same thresholds as before)
public string format_size(int64 size) {
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

public DateTime? get_file_mtime(string path) {
    try {
        var info = File.new_for_path(path).query_info("time::modified",
                                                      FileQueryInfoFlags.NONE);
        return info.get_modification_date_time();
    } catch (Error e) {
        return null;
    }
}

public int64 get_file_size(string path) {
    try {
        var info = File.new_for_path(path).query_info("standard::size",
                                                      FileQueryInfoFlags.NONE);
        return info.get_size();
    } catch (Error e) {
        return -1;
    }
}

// Remove an extracted temp file and its unique parent directory
public void remove_temp_file(string temp_path, string temp_dir) {
    try {
        File.new_for_path(temp_path).delete();
    } catch (Error e) {
        // Temp file already gone
    }
    DirUtils.remove(temp_dir);
}
