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
    // rather than relying on "nitrogen --restore" to paint it.
    //
    // Deliberately simple for a first pass, to keep this safe after the
    // last regression: reads only the first "file=" line found (ignores
    // nitrogen's per-monitor sections -- one wallpaper across all screens),
    // always stretches to fill (no aspect-ratio-preserving crop yet), and
    // is loaded once at startup (won't pick up a wallpaper changed via
    // nitrogen while Manokwari is already running -- needs a fresh login).
    private Gdk.Pixbuf? wallpaper_pixbuf = null;

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
            wallpaper_pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, geo.width, geo.height, false);
        } catch (Error e) {
            stderr.printf ("Unable to load wallpaper %s: %s\n", path, e.message);
            wallpaper_pixbuf = null;
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

