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

        set_type_hint (Gdk.WindowTypeHint.DESKTOP);

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

