// Fase 1 (Milestone 3, Opsi B): native GTK replacement for the WebKit-based
// menu.html start menu. Talks directly to the same Vala classes menu.html
// used to call into over the JS bridge (PanelUser, PanelSessionManager) --
// no JSON/JS layer needed anymore. App listing uses GLib.AppInfo/
// GLib.DesktopAppInfo (GIO, already a dependency) instead of the removed
// libgnome-menu-3.0/GMenu.Tree.
//
// Class kept as "PanelMenuHTML" to match the existing contract expected by
// panel-menu-box.vala (start/triggerShowAnimation/triggerHideAnimation/
// handleEsc) from the Milestone 1 stub -- only the implementation changes,
// not the interface, so the consumer needed zero changes.

class PanelMenuAppRow : Gtk.ListBoxRow {
    public AppInfo app_info;

    public PanelMenuAppRow (AppInfo info) {
        app_info = info;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        box.margin = 4;

        var gicon = info.get_icon ();
        Gtk.Image icon;
        if (gicon != null) {
            icon = new Gtk.Image.from_gicon (gicon, Gtk.IconSize.LARGE_TOOLBAR);
        } else {
            icon = new Gtk.Image.from_icon_name ("application-x-executable", Gtk.IconSize.LARGE_TOOLBAR);
        }
        box.pack_start (icon, false, false, 0);

        var label = new Gtk.Label (info.get_display_name ());
        label.halign = Gtk.Align.START;
        box.pack_start (label, true, true, 0);

        add (box);
    }
}

class PanelMenuPlaceRow : Gtk.ListBoxRow {
    public string uri;

    public PanelMenuPlaceRow (string name, string icon_name, string target_uri) {
        uri = target_uri;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.margin = 4;
        box.pack_start (new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU), false, false, 0);
        var label = new Gtk.Label (name);
        label.halign = Gtk.Align.START;
        box.pack_start (label, true, true, 0);
        add (box);
    }
}

public class PanelMenuHTML : Gtk.Box {
    Gtk.SearchEntry search_entry;
    Gtk.ListBox app_list;
    PanelUser user;

    public PanelMenuHTML () {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        user = new PanelUser ();

        pack_start (build_header (), false, false, 0);
        pack_start (build_search (), false, false, 6);

        var scroller = new Gtk.ScrolledWindow (null, null);
        scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        app_list = new Gtk.ListBox ();
        app_list.set_selection_mode (Gtk.SelectionMode.NONE);
        app_list.row_activated.connect (on_app_row_activated);
        scroller.add (app_list);
        pack_start (scroller, true, true, 0);

        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 4);
        pack_start (build_places (), false, false, 4);
        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 4);
        pack_start (build_session_buttons (), false, false, 8);
    }

    Gtk.Widget build_header () {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        box.margin = 10;

        var avatar_file = File.new_for_path (user.icon_file);
        Gtk.Image avatar;
        if (avatar_file.query_exists ()) {
            avatar = new Gtk.Image.from_file (user.icon_file);
        } else {
            avatar = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
        }
        avatar.set_pixel_size (48);
        box.pack_start (avatar, false, false, 0);

        var labels = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        var name_label = new Gtk.Label (user.real_name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("title-3");
        var host_label = new Gtk.Label (user.host_name);
        host_label.halign = Gtk.Align.START;
        host_label.get_style_context ().add_class ("dim-label");
        labels.pack_start (name_label, false, false, 0);
        labels.pack_start (host_label, false, false, 0);
        box.pack_start (labels, true, true, 0);

        return box;
    }

    Gtk.Widget build_search () {
        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Search applications...");
        search_entry.margin_start = 10;
        search_entry.margin_end = 10;
        search_entry.search_changed.connect (populate_apps);
        return search_entry;
    }

    void populate_apps () {
        foreach (var child in app_list.get_children ()) {
            app_list.remove (child);
        }

        var query = search_entry.text.down ();
        var apps = AppInfo.get_all ();
        apps.sort ((a, b) => {
            return strcmp (a.get_display_name () ?? "", b.get_display_name () ?? "");
        });

        foreach (var app in apps) {
            if (!app.should_show ()) {
                continue;
            }
            var name = app.get_display_name () ?? "";
            if (query != "" && !(name.down ().contains (query))) {
                continue;
            }
            app_list.add (new PanelMenuAppRow (app));
        }
        app_list.show_all ();
    }

    void on_app_row_activated (Gtk.ListBoxRow row) {
        var app_row = row as PanelMenuAppRow;
        if (app_row == null) return;
        try {
            app_row.app_info.launch (null, null);
        } catch (Error e) {
            stderr.printf ("Unable to launch %s: %s\n", app_row.app_info.get_display_name (), e.message);
        }
    }

    Gtk.Widget build_places () {
        var list = new Gtk.ListBox ();
        list.set_selection_mode (Gtk.SelectionMode.NONE);
        list.row_activated.connect ((row) => {
            var place_row = row as PanelMenuPlaceRow;
            if (place_row == null) return;
            try {
                AppInfo.launch_default_for_uri (place_row.uri, null);
            } catch (Error e) {
                stderr.printf ("Unable to open %s: %s\n", place_row.uri, e.message);
            }
        });

        var home = File.new_for_path (Environment.get_home_dir ());
        list.add (new PanelMenuPlaceRow (_("Home"), "user-home", home.get_uri ()));

        UserDirectory[] dirs = {
            UserDirectory.DESKTOP, UserDirectory.DOCUMENTS, UserDirectory.DOWNLOAD,
            UserDirectory.MUSIC, UserDirectory.PICTURES, UserDirectory.VIDEOS
        };
        foreach (var d in dirs) {
            var path = Environment.get_user_special_dir (d);
            if (path != null) {
                var f = File.new_for_path (path);
                list.add (new PanelMenuPlaceRow (Path.get_basename (path), "folder", f.get_uri ()));
            }
        }

        var monitor = VolumeMonitor.get ();
        foreach (var mount in monitor.get_mounts ()) {
            list.add (new PanelMenuPlaceRow (mount.get_name (), "drive-harddisk", mount.get_root ().get_uri ()));
        }

        return list;
    }

    Gtk.Widget build_session_buttons () {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
        box.halign = Gtk.Align.CENTER;

        var lock_btn = new Gtk.Button ();
        lock_btn.set_relief (Gtk.ReliefStyle.NONE);
        lock_btn.set_image (new Gtk.Image.from_icon_name ("system-lock-screen", Gtk.IconSize.LARGE_TOOLBAR));
        lock_btn.set_tooltip_text (_("Lock"));
        lock_btn.clicked.connect (() => { Utils.lock_screen (); });
        box.pack_start (lock_btn, false, false, 0);

        var logout_btn = new Gtk.Button ();
        logout_btn.set_relief (Gtk.ReliefStyle.NONE);
        logout_btn.set_image (new Gtk.Image.from_icon_name ("system-log-out", Gtk.IconSize.LARGE_TOOLBAR));
        logout_btn.set_tooltip_text (_("Logout"));
        logout_btn.clicked.connect (() => { PanelSessionManager.getInstance ().logout.begin (); });
        box.pack_start (logout_btn, false, false, 0);

        var restart_btn = new Gtk.Button ();
        restart_btn.set_relief (Gtk.ReliefStyle.NONE);
        restart_btn.set_image (new Gtk.Image.from_icon_name ("system-reboot", Gtk.IconSize.LARGE_TOOLBAR));
        restart_btn.set_tooltip_text (_("Restart"));
        restart_btn.clicked.connect (() => {
            // Milestone 5 Tahap 1: confirm before acting, using
            // PanelEndSessionDialog (kept unused since Milestone 3 for
            // exactly this). type=2 is restart; the dialog also
            // auto-confirms itself after a 10s countdown if not canceled,
            // matching the original gnome-session behavior.
            var dialog = new PanelEndSessionDialog ();
            dialog.confirmed_reboot.connect (() => {
                PanelSessionManager.getInstance ().reboot.begin ();
            });
            dialog.open.begin (2, 0, 0, {});
        });
        box.pack_start (restart_btn, false, false, 0);

        if (PanelSessionManager.getInstance ().can_shutdown ()) {
            var shutdown_btn = new Gtk.Button ();
            shutdown_btn.set_relief (Gtk.ReliefStyle.NONE);
            shutdown_btn.set_image (new Gtk.Image.from_icon_name ("system-shutdown", Gtk.IconSize.LARGE_TOOLBAR));
            shutdown_btn.set_tooltip_text (_("Shutdown"));
            shutdown_btn.clicked.connect (() => {
                // type=1 is shutdown -- same dialog/countdown pattern as restart.
                var dialog = new PanelEndSessionDialog ();
                dialog.confirmed_shutdown.connect (() => {
                    PanelSessionManager.getInstance ().shutdown.begin ();
                });
                dialog.open.begin (1, 0, 0, {});
            });
            box.pack_start (shutdown_btn, false, false, 0);
        }

        return box;
    }

    public void start () {
        populate_apps ();
    }

    public void triggerShowAnimation () {
        search_entry.text = "";
        search_entry.grab_focus ();
    }

    public void triggerHideAnimation () {
    }

    public bool handleEsc () {
        if (search_entry.text != "") {
            search_entry.text = "";
            populate_apps ();
            return true;
        }
        return false;
    }
}
