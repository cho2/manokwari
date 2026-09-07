// Fase 2 (Milestone 3, Opsi B): native GTK replacement for the WebKit-based
// desktop.html sidebar/bevel. Per project decision, everything except the
// clock is dropped -- BlankOn-branded bookmarks, music player, weather
// widget ("Tekukur"), and the 14-icon system settings grid are all gone,
// not just deferred. See ROADMAP.md.
//
// Class kept as "PanelDesktopHTML" to match the existing contract expected
// by panel-desktop.vala (updateSize()) from the Milestone 1 stub -- only
// the implementation changes, consumer needed zero changes.
//
// PanelDesktop (the parent window) is transparent and sized to the full
// monitor on purpose (it exists to catch clicks anywhere on the desktop and
// fire desktop_clicked(), used to auto-close the menu). This widget fills
// that same full area but only actually draws content in the corner, via
// halign/valign -- same positioning the original CSS bevel used ("right
// bottom of the screen", per time.js's own comment).

public class PanelDesktopHTML : Gtk.Box {
    Gtk.Label time_label;
    Gtk.Label date_label;
    uint timeout_id = 0;

    public PanelDesktopHTML () {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 2);

        halign = Gtk.Align.END;
        valign = Gtk.Align.END;
        margin = 16;

        var css = new Gtk.CssProvider ();
        try {
            css.load_from_data (
                ".manokwari-clock-time { font-size: 28px; font-weight: bold; color: #ffffff; }" +
                ".manokwari-clock-date { font-size: 13px; color: #dddddd; }"
            );
        } catch (Error e) {
            stderr.printf ("Unable to load clock CSS: %s\n", e.message);
        }

        time_label = new Gtk.Label ("");
        time_label.halign = Gtk.Align.END;
        time_label.get_style_context ().add_provider (css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        time_label.get_style_context ().add_class ("manokwari-clock-time");

        date_label = new Gtk.Label ("");
        date_label.halign = Gtk.Align.END;
        date_label.get_style_context ().add_provider (css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        date_label.get_style_context ().add_class ("manokwari-clock-date");

        pack_start (time_label, false, false, 0);
        pack_start (date_label, false, false, 0);

        update_clock ();
        // Same 1s interval the original Clock.prototype.update() used
        // (via setTimeout), even though only the minute is displayed --
        // matches original behavior rather than "optimizing" to 60s, in
        // case a future change adds seconds back.
        timeout_id = Timeout.add_seconds (1, () => {
            update_clock ();
            return true;
        });

        destroy.connect (() => {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
        });
    }

    void update_clock () {
        var now = new DateTime.now_local ();
        // Same format the original used (moment.js "HH:mm" / "ddd, DD MMMM YYYY"),
        // via GLib.DateTime's strftime-style directives. %a/%B are locale-aware
        // (follow the system's LC_TIME), rather than hardcoding Indonesian like
        // the original did -- consistent with this project's generic/freedesktop
        // direction rather than assuming one language.
        time_label.set_text (now.format ("%H:%M"));
        date_label.set_text (now.format ("%a, %d %B %Y"));
    }

    // Kept for panel-desktop.vala's existing call site (resize_geometry()) --
    // no-op now since GTK's own layout system re-flows halign/valign
    // positioning automatically on allocation changes, unlike the CSS
    // transform math the original JS had to do by hand.
    public void updateSize () {}
}
