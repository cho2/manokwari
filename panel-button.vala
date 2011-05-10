using Gtk;
using Cairo;
using GMenu;

public class PanelButtonWindow : PanelAbstractWindow {

    private ImageSurface surface;
    private PanelMenuBox menu_box;
    private Gdk.Rectangle rect;
    private Gdk.Pixbuf logo;
    private bool hiding;

    private bool hide_menu_box () {
        stdout.printf ("xxxxxxxx\n");
        if (!hiding)
            return false;

        menu_box.hide ();
        hiding = false;
        return false;
    }

    public PanelButtonWindow() {
        set_type_hint (Gdk.WindowTypeHint.DOCK);
        add_events (Gdk.EventMask.STRUCTURE_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        menu_box = new PanelMenuBox();
        set_visual (this.screen.get_rgba_visual ());

        set_size_request (40,40);
        set_keep_above(true);

        Gdk.RGBA c = Gdk.RGBA();
        c.red = 0.0;
        c.blue = 0.0;
        c.green = 0.0;
        c.alpha = 0.0;
        override_background_color(StateFlags.NORMAL, c);
        set_app_paintable(true);
        
        var screen = get_screen();
        screen.get_monitor_geometry (screen.get_primary_monitor(), out rect);
        move (rect.x, rect.y);

        var icon_theme = IconTheme.get_default();
        logo = icon_theme.load_icon ("distributor-logo", 30, IconLookupFlags.GENERIC_FALLBACK);

        leave_notify_event.connect (() => {
            //hiding = true;
            //GLib.Timeout.add (250, hide_menu_box); 
            return false;
        });
        enter_notify_event.connect (() => {
            if (hiding) 
                return false;
        stdout.printf ("xxxxxxxx1\n");
            GLib.Timeout.add (100, show_menu_box); 
            return false;
        });
        button_press_event.connect (() => {
            if (hiding == false) { 
        stdout.printf ("xxxxxxxx2\n");
                hiding = true;
                GLib.Timeout.add (250, hide_menu_box); 
            } else {
        stdout.printf ("xxxxxxxx3\n");
                show_menu_box ();
            }
            return false;
        });

    }

    public override bool draw (Context cr)
    {

        if (logo != null)
            Gdk.cairo_set_source_pixbuf (cr, logo, 0, 0);
        cr.paint();
        return false;
    }

    private bool show_menu_box () {
        menu_box.show_all ();
        get_window ().raise ();
        menu_box.get_window ().lower ();
        return false;
    }

}
