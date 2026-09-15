using Gtk;
using Cairo;

// Milestone 4 (revisit): the desktop bevel/sidebar is removed outright, not
// just emptied. Its clock was genuinely redundant -- the taskbar already
// has its own (PanelClock, src/panel-clock.vala, pre-existing and
// unrelated to any of our Milestone 3 work). PanelDesktop's OTHER role --
// a full-screen transparent window that catches clicks on the desktop to
// auto-close the menu (desktop_clicked signal) -- is unrelated to the
// bevel content and stays exactly as it was, just moved from the now-gone
// child widget onto the window itself.

public class PanelDesktop: PanelAbstractWindow {

    public signal void desktop_clicked();

    // Milestone 5 Tahap 2 (2nd attempt, after the window-hint approach
    // caused a black-screen regression): draw the wallpaper ourselves,
    // directly into this already-working, already-tested window, instead
    // of asking nitrogen to find and paint onto/around it -- nitrogen's
    // own root-window-scanning mechanism is exactly what conflicted with
    // our DESKTOP-type window in the first place. nitrogen is still used
    // as the picker (run it manually to choose a wallpaper -- see
    // TESTING.md); we just read ITS saved config ourselves afterward
    // rather than relying on "nitrogen --restore" to paint it. Note
    // nitrogen still attempts (and fails, same conflict) its own paint
    // whenever you apply a NEW image from its GUI -- harmless now since
    // we don't depend on it succeeding, but the warning will still appear
    // in nitrogen's own log at that moment. Not something we can suppress
    // from our side.
    //
    // Reads only the first "file=" line found (ignores nitrogen's
    // per-monitor sections -- one wallpaper across all screens). Uses a
    // "cover" (aspect-preserving, crop-to-fill) scale rather than
    // replicating nitrogen's full mode system (Automatic/Centered/Tiled/
    // Scaled/Zoomed/Zoomed Fill) -- one reasonable default, not a faithful
    // reproduction of whatever mode nitrogen's config says. A FileMonitor
    // watches nitrogen's config file, so changing wallpaper via nitrogen's
    // GUI while Manokwari is running updates it live -- no need to log
    // out/in anymore.
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
            // Load at native size first to compute a "cover" (crop-to-fill)
            // scale factor -- looks much better than stretching for images
            // that don't exactly match the screen's aspect ratio.
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
            // Non-fatal -- e.g. ~/.config/nitrogen/ not existing yet because
            // nitrogen has genuinely never been run. Wallpaper changes just
            // won't be picked up live until next login in that case, same
            // as the previous (pre-FileMonitor) behavior for everyone.
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

        // REVERTED (Milestone 5 Tahap 2): the previous commit swapped this
        // for set_keep_below(true)/set_decorated(false)/set_accept_focus(false)
        // to stop nitrogen misidentifying this window -- but that caused a
        // full black-screen regression on real hardware (entire screen
        // black, only cursor visible), almost certainly because picom
        // treats DESKTOP-type windows specially for RGBA compositing, and
        // a NORMAL-type window with the same alpha=0 background doesn't
        // get the same treatment. A cosmetic nitrogen warning + wallpaper
        // not showing is a strictly better failure mode than an unusable
        // black screen -- reverted rather than iterate further on window
        // hints blind. Real fix for the nitrogen conflict now needs a
        // different approach that doesn't touch this hint at all (e.g.
        // painting the wallpaper directly into this already-controlled
        // window instead of relying on nitrogen to find/draw onto it).
        set_type_hint (Gdk.WindowTypeHint.DESKTOP);

        load_wallpaper ();
        setup_wallpaper_monitor ();
        draw.connect ((cr) => {
            if (wallpaper_pixbuf == null) {
                // No wallpaper found/loaded -- do nothing at all, same as
                // before this change existed. The alpha=0 background set
                // above is what shows through.
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

