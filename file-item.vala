/*
 * ISO Master - file item model used by the browser list views
 */

public class FileItem : Object {
    public string name { get; set; }
    public string path { get; set; }
    public bool is_dir { get; set; }
    public string icon_name { get; set; }
    public int64 size { get; set; }
}
