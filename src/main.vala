using Gtk;
int main (string[] args) {

    var settings = new GLib.Settings ("org.gnome.system.locale");
    var region = settings.get_string ("region");

    if (region != null && region != "") {
      GLib.Environment.set_variable("LC_MESSAGES", region, true);
      GLib.Environment.set_variable("LC_TIME", region, true);
      GLib.Environment.set_variable("LC_ALL", region, true);
      GLib.Environment.set_variable("LANG", region, true);
    }

    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.setlocale(LocaleCategory.MESSAGES, "");
    Intl.setlocale(LocaleCategory.TIME, "");

    Intl.bindtextdomain( Config.GETTEXT_PACKAGE, Config.LOCALEDIR );
    Intl.bind_textdomain_codeset( Config.GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( Config.GETTEXT_PACKAGE );

 
    Gtk.init (ref args);

    // STUB (Milestone 1): Unique.App single-instance check removed along with
    // unique-3.0 (dead upstream). Real replacement is GApplication/GtkApplication
    // in Milestone 3 -- same app id string carries over unchanged.
    // var id = GLib.Environment.get_variable("DESKTOP_AUTOSTART_ID");
    // var app = new Unique.App ("io.github.cho2.Manokwari", id);
    // if (app.is_running ()) {
    //     stdout.printf ("Manokwari is already running.\n");
    //     return 0;
    // }

    PanelSessionManager.getInstance ();
    Bus.own_name(
        BusType.SESSION,
        "org.gnome.Panel",
        0,
        () => {},
        () => {},
        () => {
          stderr.printf ("Unable to claim Panel from gnome-session");
        }
    );

    // Shell
    var shell = new PanelShell();

    // Desktop
    var d = new PanelDesktop ();
    d.show ();

    // Window 
    var w = new PanelWindowHost ();
    w.show();

    var menu_box = new PanelMenuBox();
    // SIGNALS
    w.menu_clicked.connect (() => {
        if (menu_box.visible) {
            menu_box.try_hide ();
        } else {
            // Otherwise we want to show it
            menu_box.show ();
        }
    });

    w.dialog_opened.connect (() => {
        if (menu_box.visible) {
            menu_box.try_hide ();
        }
    });

    d.desktop_clicked.connect (() => {
        if (menu_box.visible) {
            menu_box.try_hide ();
        }
    });

    w.windows_visible.connect (() => {
        if (menu_box.visible) {
            menu_box.try_hide ();
        }
    });


    Gtk.main ();
    return 0;
}
