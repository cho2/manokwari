using Gtk;

public class PanelMenuBox : PanelAbstractWindow {
    private Gdk.Rectangle rect;
    private VBox box;
    private MenuBar menu_bar;

    public PanelMenuBox () {
        PanelMenuContent favorites;
        PanelMenuContent applications;

        set_type_hint (Gdk.WindowTypeHint.DOCK);
        var screen = get_screen();
        screen.get_monitor_geometry (screen.get_primary_monitor(), out rect);
        move (rect.x, rect.y);
        box = new VBox (false, 0);
        add (box);

        var filler = new DrawingArea ();
        filler.set_size_request(27, 27); // TODO
        box.pack_start (filler, false, false, 0);

        menu_bar = new MenuBar ();
        menu_bar.set_pack_direction (PackDirection.TTB);

        favorites = new PanelMenuContent (menu_bar, "favorites.menu");

        favorites.menu_clicked.connect (() => {
            dismiss ();
        });

        applications = new PanelMenuContent (menu_bar, "applications.menu");
        applications.menu_clicked.connect (() => {
            dismiss ();
        });


        favorites.populate ();
        favorites.insert_separator ();
        applications.populate ();

        box.pack_start (menu_bar, false, false);

    }

    public override void get_preferred_width (out int min, out int max) {
        min = max = 300; 
    }

    public override void get_preferred_height (out int min, out int max) {
        // TODO
        min = max = rect.height; 
    }

    public override bool map_event (Gdk.Event event) {
        var device = get_current_event_device();

        if (device == null) {
            var display = get_display ();
            var manager = display.get_device_manager ();
            var devices = manager.list_devices (Gdk.DeviceType.MASTER).copy();
            device = devices.data;
        }
        var keyboard = device;
        var pointer = device;

        if (device.get_source() == Gdk.InputSource.KEYBOARD) {
            pointer = device.get_associated_device ();
        } else {
            keyboard = device.get_associated_device ();
        }


        var status = keyboard.grab(get_window(), Gdk.GrabOwnership.WINDOW, true, Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK, null, Gdk.CURRENT_TIME);
        status = pointer.grab(get_window(), Gdk.GrabOwnership.WINDOW, true, Gdk.EventMask.BUTTON_PRESS_MASK, null, Gdk.CURRENT_TIME);
        return true;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        dismiss ();
        return true;
    }

    private void dismiss () {
        var device = get_current_event_device();
        var secondary = device.get_associated_device();
        device.ungrab(Gdk.CURRENT_TIME);
        secondary.ungrab(Gdk.CURRENT_TIME);
        hide();
    }
}