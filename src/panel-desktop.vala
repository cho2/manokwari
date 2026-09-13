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

    public PanelDesktop() {
        set_visual (this.screen.get_rgba_visual ());

        Gdk.RGBA c = Gdk.RGBA();
        c.red = 0.0;
        c.blue = 0.0;
        c.green = 0.0;
        c.alpha = 0.0;
        override_background_color(StateFlags.NORMAL, c);
        set_app_paintable(true);

        // Milestone 5 Tahap 2 follow-up: was set_type_hint(Gdk.WindowTypeHint.DESKTOP).
        // Real-world testing found this conflicts with nitrogen (the
        // wallpaper tool added earlier in this same Tahap): nitrogen scans
        // for a window of exactly this X11 type to figure out how to draw
        // the background, found ours instead (WM_CLASS "Manokwari", which
        // it doesn't recognize as one of the desktop-icon managers it has
        // special handling for -- Nautilus, PCManFM, Nemo, etc.), and
        // failed with "UNKNOWN ROOT WINDOW TYPE DETECTED (Manokwari)"
        // (confirmed against nitrogen's own source, src/SetBG.cc, and
        // several near-identical upstream bug reports from other unrelated
        // programs that make the same mistake -- Easystroke, Tilda,
        // AwesomeWM -- of claiming the DESKTOP type for unrelated reasons).
        //
        // Replaced with the same practical behavior (undecorated, no
        // focus, always below other windows) via different, more specific
        // hints instead of the single DESKTOP type that bundles all of
        // that together *and* signals "I am the desktop" to anything
        // scanning for it. NOT yet live-tested against a real Openbox
        // session -- please confirm this both fixes nitrogen AND still
        // keeps click-catching/stacking behaving the same as before.
        set_type_hint (Gdk.WindowTypeHint.NORMAL);
        set_decorated (false);
        set_accept_focus (false);
        set_keep_below (true);

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

