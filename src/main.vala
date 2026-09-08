using Gtk;
int main (string[] args) {

    // Milestone 3: unique-3.0 replaced with GLib.Application. register() claims
    // the app id as a well-known D-Bus name on the session bus -- same mechanism
    // Unique.App used internally, just via the generic freedesktop/GIO API instead
    // of a dead GNOME-only library. Same app id string as before, unchanged.
    var app = new GLib.Application ("io.github.cho2.Manokwari", ApplicationFlags.FLAGS_NONE);
    try {
        app.register ();
    } catch (GLib.Error e) {
        stderr.printf ("Unable to register application: %s\n", e.message);
    }

    if (app.get_is_remote ()) {
        stdout.printf ("Manokwari is already running.\n");
        return 0;
    }

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

    PanelSessionManager.getInstance ();
    // Milestone 3: Bus.own_name("org.gnome.Panel", ...) removed -- it only
    // existed to signal gnome-session "the panel started", which no longer
    // applies (see files/bin/manokwari-session). Same for `new PanelShell()`
    // below -- see the comment in panel-shell.vala.

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
