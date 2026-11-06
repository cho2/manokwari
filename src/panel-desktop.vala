using Gtk;
using Cairo;

public class PanelDesktop: PanelAbstractWindow {

    public signal void desktop_clicked();

    private Gdk.Pixbuf? wallpaper_pixbuf = null;
    private FileMonitor? wallpaper_monitor = null;

    string? find_wallpaper_path () {
        var config_path = GLib.Path.build_filename (
            Environment.get_home_dir (), ".config", "nitrogen", "bg-saved.cfg");
        if (!FileUtils.test (config_path, FileTest.EXISTS)) {
            return null;
        }
        try {
            string contents;
            FileUtils.get_contents (config_path, out contents);
            foreach (var line in contents.split ("\n")) {
                var trimmed = line.strip ();
                if (trimmed.has_prefix ("file=")) {
                    return trimmed.substring (5).strip ();
                }
            }
        } catch (FileError e) {
            stderr.printf ("Unable to read nitrogen config: %s\n", e.message);
        }
        return null;
    }

    void load_wallpaper () {
        var path = find_wallpaper_path ();
        if (path == null || !FileUtils.test (path, FileTest.EXISTS)) {
            wallpaper_pixbuf = null;
            return;
        }
        try {
            var geo = PanelScreen.get_primary_monitor_geometry ();
            var original = new Gdk.Pixbuf.from_file (path);
            double scale = double.max (
                (double) geo.width / original.get_width (),
                (double) geo.height / original.get_height ());
            int scaled_width = (int) (original.get_width () * scale) + 1;
            int scaled_height = (int) (original.get_height () * scale) + 1;
            var scaled = original.scale_simple (scaled_width, scaled_height, Gdk.InterpType.BILINEAR);
            int offset_x = (scaled_width - geo.width) / 2;
            int offset_y = (scaled_height - geo.height) / 2;
            wallpaper_pixbuf = new Gdk.Pixbuf.subpixbuf (scaled, offset_x, offset_y, geo.width, geo.height);
        } catch (Error e) {
            stderr.printf ("Unable to load wallpaper %s: %s\n", path, e.message);
            wallpaper_pixbuf = null;
        }
    }

    void setup_wallpaper_monitor () {
        var config_path = GLib.Path.build_filename (
            Environment.get_home_dir (), ".config", "nitrogen", "bg-saved.cfg");
        try {
            var file = File.new_for_path (config_path);
            wallpaper_monitor = file.monitor_file (FileMonitorFlags.NONE, null);
            wallpaper_monitor.changed.connect ((src, dest, event) => {
                load_wallpaper ();
                queue_draw ();
            });
        } catch (Error e) {
            stderr.printf ("Unable to watch nitrogen config for changes: %s\n", e.message);
        }
    }

    public PanelDesktop() {
        set_visual (this.screen.get_rgba_visual ());

        Gdk.RGBA c = Gdk.RGBA();
        c.red = 0.0;
        c.blue = 0.0;
        c.green = 0.0;
        c.alpha = 0.0;
        override_background_color(StateFlags.NORMAL, c);
        set_app_paintable(true);

        set_type_hint (Gdk.WindowTypeHint.DESKTOP);

        load_wallpaper ();
        setup_wallpaper_monitor ();
        draw.connect ((cr) => {
            if (wallpaper_pixbuf == null) {
                return false;
            }
            Gdk.cairo_set_source_pixbuf (cr, wallpaper_pixbuf, 0, 0);
            cr.paint ();
            return true;
        });

        queue_resize ();

        move (0, 0);
        show_all ();

        button_press_event.connect (() => {
            desktop_clicked ();
            return false;
        });

        screen.size_changed.connect (() =>  {
            resize_geometry ();
        });

        screen.monitors_changed.connect (() =>  {
            resize_geometry ();
        });

        
        key_press_event.connect ((e) => {					//Printscreen
            if (Gdk.keyval_name(e.keyval) == "Print") {
                if (Utils.print_screen () == false) {
                    stdout.printf ("Unable to take screenshot\n");
                }
            }
            return false;
        });

    }

    void resize_geometry() {
        PanelScreen.move_window (this, Gdk.Gravity.NORTH_EAST);

        queue_resize ();
        stderr.printf("iii %d %d <--\n", screen.width(), screen.height());
    }

    public override void get_preferred_width (out int min, out int max) {
        var r = PanelScreen.get_primary_monitor_geometry ().width;
        min = max = r;
    }

    public override void get_preferred_height (out int min, out int max) {
        var r = PanelScreen.get_primary_monitor_geometry ().height;
        min = max = r;
    }


}

