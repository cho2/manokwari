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
    Gtk.ListBox app_list;        // used in search mode
    Gtk.Widget category_box;     // used in browse mode (default)
    Gtk.ScrolledWindow scroller; // shared container, swaps content

    // Category definitions for 3c. Order here = display order (alphabetical).
    // XDG Categories= values that map to each label.
    // Source: files/menus/manokwari-applications.menu (kept in tree for reference).
    // Dropped: Geo.BlankOn (Category=Peta, BlankOn-specific),
    //          Debian (merge file, Milestone 4 decision).
    // Kept:    Islamic-Software (Category=X-Islamic-Software, on request).
    private const string[,] CATEGORIES = {
        { "Accessories",      "Utility"           },
        { "Administration",   "Settings:System"   },  // AND: both required
        { "Development",      "Development"       },
        { "Education",        "Education"         },
        { "Games",            "Game"              },
        { "Graphics",         "Graphics"          },
        { "Internet",         "Network"           },
        { "Islamic Software", "X-Islamic-Software"},
        { "Multimedia",       "AudioVideo"        },
        { "Office",           "Office"            },
        { "Preferences",      "Settings"          },  // Settings but NOT System
        { "Science",          "Science"           },
        { "System",           "System"            },
        { "Universal",        "Accessibility"     },
        { "YaST",             "X-SuSE-YaST"       },
        { "Other",            ""                  },  // catch-all, filled last
    };

    // Builds a mapping of category label → sorted list of AppInfo.
    // Apps that match no category land in "Other".
    // Apps are sorted alphabetically within each category.
    // Returned keys preserve CATEGORIES order (insertion-ordered HashMap
    // from libgee).
    Gee.HashMap<string, Gee.ArrayList<AppInfo>> build_category_map () {
        var map = new Gee.HashMap<string, Gee.ArrayList<AppInfo>> ();

        // Pre-populate in display order so keys are always in CATEGORIES order.
        int n = CATEGORIES.length[0];
        for (int i = 0; i < n; i++) {
            map.set (CATEGORIES[i, 0], new Gee.ArrayList<AppInfo> ());
        }

        var all_apps = AppInfo.get_all ();
        all_apps.sort ((a, b) => strcmp (
            a.get_display_name () ?? "",
            b.get_display_name () ?? ""));

        foreach (var app in all_apps) {
            if (!app.should_show ()) continue;

            var dai = app as DesktopAppInfo;
            if (dai == null) continue;

            var cats_raw = dai.get_categories () ?? "";
            var cats = cats_raw.split (";");

            bool placed = false;

            // YaST first: its modules also carry Settings;System, so the
            // generic "Administration" rule (Settings AND System) would
            // otherwise claim them before the YaST row is ever reached.
            foreach (var c in cats) {
                if (c == "X-SuSE-YaST") {
                    map.get ("YaST").add (app);
                    placed = true;
                    break;
                }
            }

            for (int i = 0; !placed && i < n - 1; i++) {  // skip "Other" (last)
                var label = CATEGORIES[i, 0];
                var required = CATEGORIES[i, 1];

                if (required == "") continue;

                if (required.contains (":")) {
                    // AND logic: all tokens must be present (e.g. "Settings:System")
                    var tokens = required.split (":");
                    bool all_match = true;
                    foreach (var token in tokens) {
                        bool found = false;
                        foreach (var c in cats) {
                            if (c == token) { found = true; break; }
                        }
                        if (!found) { all_match = false; break; }
                    }
                    if (all_match) {
                        map.get (label).add (app);
                        placed = true;
                        break;
                    }
                } else {
                    // Single category match
                    foreach (var c in cats) {
                        if (c == required) {
                            map.get (label).add (app);
                            placed = true;
                            break;
                        }
                    }
                    if (placed) break;
                }
            }

            if (!placed) {
                map.get ("Other").add (app);
            }
        }

        return map;
    }    

    Gtk.Widget build_category_ui () {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var cat_map = build_category_map ();

        int n = CATEGORIES.length[0];
        for (int i = 0; i < n; i++) {
            var label = CATEGORIES[i, 0];
            var apps  = cat_map.get (label);
            if (apps == null || apps.size == 0) continue;

            // Category header row (same pattern as Locations in 3b)
            var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            header_box.margin = 4;
            header_box.get_style_context ().add_class ("manokwari-category-header");

            var arrow = new Gtk.Label ("▶");
            arrow.get_style_context ().add_class ("manokwari-category-arrow");
            header_box.pack_start (arrow, false, false, 4);

            var title = new Gtk.Label (label);
            title.halign = Gtk.Align.START;
            header_box.pack_start (title, true, true, 0);

            var revealer = new Gtk.Revealer ();
            revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
            revealer.set_transition_duration (150);
            revealer.set_reveal_child (false);

            var header_btn = new Gtk.EventBox ();
            header_btn.add (header_box);
            header_btn.button_press_event.connect (() => {
                var expanded = !revealer.get_reveal_child ();
                revealer.set_reveal_child (expanded);
                arrow.set_text (expanded ? "▼" : "▶");
                return true;
            });
            box.pack_start (header_btn, false, false, 0);

            // App list inside revealer
            var app_list_cat = new Gtk.ListBox ();
            app_list_cat.set_selection_mode (Gtk.SelectionMode.NONE);
            app_list_cat.get_style_context ().add_class ("manokwari-category-list");
            app_list_cat.row_activated.connect (on_app_row_activated);

            foreach (var app in apps) {
                app_list_cat.add (new PanelMenuAppRow (app));
            }
            app_list_cat.show_all ();

            revealer.add (app_list_cat);
            box.pack_start (revealer, false, false, 0);
        }

        box.show_all ();
        return box;
    }
    // Milestone 5 Tahap 2: lets the session buttons ask PanelMenuBox (the
    // containing window) to dismiss itself. Needed because PanelMenuBox
    // holds an X11 keyboard+pointer grab the whole time the menu is open,
    // and only its own dismiss() releases it -- see the Lock button below.
    public signal void dismiss_requested ();

    // Milestone 5 Tahap 3: styling modeled on the pre-fork Manokwari's own
    // stylesheets, which are still in the tree for reference even though
    // they're no longer installed (system/css/style.css and sessions.css).
    // Colors/shapes taken directly from there: #111 page background, #151515
    // rows with #aaa text, #333/#fff on hover, #1a1a1a, the
    // rounded #2a2a2a search field, #151515 session bar, #333 scrollbar.
    //
    // NOT a pixel-perfect reproduction, and can't be: the original's fonts
    // (Aurulent Sans, Trendex) live in system/fonts/, which stopped being
    // installed back in Milestone 3 when the whole WebKit frontend went
    // away -- so this uses the system font instead. Sizes/weights are
    // approximated to match the original's proportions.
    //
    // Every selector is scoped under .manokwari-menu on purpose: the
    // provider is registered screen-wide (that's how GTK3 CSS works), so
    // without that scoping this would also restyle the taskbar, the
    // confirmation dialogs, and anything else this process draws.
    const string MENU_CSS = """
    .manokwari-menu {
        background-color: #111111;
        color: #aaaaaa;
        font-family: "Aurulent Sans", sans-serif;
    }
    .manokwari-menu entry {
        background-image: none;
        background-color: #2a2a2a;
        border: 2px solid #2a2a2a;
        border-radius: 20px;
        color: #aaaaaa;
        font-size: 12px;
        padding: 2px 8px;
    }
    .manokwari-menu list {
        background-color: #151515;
    }
    .manokwari-menu row {
        background-color: #151515;
        color: #aaaaaa;
        border-bottom: 1px solid #0f0f0f;
        min-height: 26px;
        font-size: 12px;
    }
    .manokwari-menu row:hover {
        background-color: #333333;
        color: #ffffff;
    }
    .manokwari-menu separator {
        background-color: #0f0f0f;
    }
    .manokwari-menu .manokwari-section-label {
        background-color: #1f1f1f;
        border-bottom: 1px solid #111111;
        color: #dddddd;
        text-shadow: 0 1px 1px #000000;
        font-size: 12px;
        padding: 3px 20px;
        min-height: 26px;
    }
    .manokwari-menu scrollbar {
        background-color: transparent;
        border: none;
    }
    .manokwari-menu scrollbar slider {
        background-color: #333333;
        border-radius: 3px;
        min-width: 6px;
    }
    .manokwari-menu scrollbar slider:hover {
        background-color: #3d3d3d;
    }
    .manokwari-sessions {
        background-color: #151515;
    }
    .manokwari-sessions button {
        background-image: none;
        background-color: transparent;
        border: none;
        box-shadow: none;
        padding: 4px;
    }
    .manokwari-sessions button:hover {
        background-color: #333333;
        border-radius: 20px;
    }
    .manokwari-places-header {
        background-color: #151515;
        color: #aaaaaa;
        font-size: 12px;
        border-bottom: 1px solid #0f0f0f;
        min-height: 26px;
    }
    .manokwari-places-header:hover {
        background-color: #333333;
        color: #ffffff;
    }
    .manokwari-places-arrow {
        color: #666666;
        font-size: 10px;
    }
    .manokwari-places-list row {
        padding-left: 20px;
    }
    .manokwari-category-header {
        background-color: #1a1a1a;
        color: #cccccc;
        font-size: 12px;
        border-bottom: 1px solid #0f0f0f;
        min-height: 26px;
    }
    .manokwari-category-header:hover {
        background-color: #333333;
        color: #ffffff;
    }
    .manokwari-category-arrow {
        color: #666666;
        font-size: 10px;
    }
    .manokwari-category-list row {
        background-color: #111111;
        color: #aaaaaa;
        border-bottom: 1px solid #0d0d0d;
        min-height: 26px;
        font-size: 12px;
        padding-left: 20px;
    }
    .manokwari-category-list row:hover {
        background-color: #333333;
        color: #ffffff;
    }
    .manokwari-menu entry:focus {
        border-color: #2a2a2a;
        box-shadow: none;
    }
    """;

    void apply_style () {
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (MENU_CSS);
        } catch (Error e) {
            stderr.printf ("Unable to load menu CSS: %s\n", e.message);
            return;
        }
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public PanelMenuHTML () {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        apply_style ();
        get_style_context ().add_class ("manokwari-menu");

        
        pack_start (make_section_label (_("Applications")), false, false, 0);
        
        pack_start (build_search (), false, false, 6);

        scroller = new Gtk.ScrolledWindow (null, null);
        scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        app_list = new Gtk.ListBox ();
        app_list.set_selection_mode (Gtk.SelectionMode.NONE);
        app_list.row_activated.connect (on_app_row_activated);

        category_box = build_category_ui ();
        scroller.add (category_box);
        pack_start (scroller, true, true, 0);

        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 4);
        pack_start (make_section_label (_("Places & Settings")), false, false, 0);
        pack_start (build_places (), false, false, 4);
        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 4);
        pack_start (make_section_label (_("Sessions")), false, false, 0);
        pack_start (build_session_buttons (), false, false, 8);
    }

    Gtk.Widget make_section_label (string text) {
        var label = new Gtk.Label (text);
        label.halign = Gtk.Align.FILL;
        label.xalign = 0.5f;
        label.get_style_context ().add_class ("manokwari-section-label");
        return label;
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
        var query = search_entry.text.down ().strip ();

        if (query == "") {
            // Browse mode: show category tree
            if (scroller.get_child () != category_box) {
                scroller.remove (scroller.get_child ());
                scroller.add (category_box);
                scroller.show_all ();
            }
            return;
        }

        // Search mode: show flat filtered list
        if (scroller.get_child () != app_list) {
            scroller.remove (scroller.get_child ());
            scroller.add (app_list);
        }

        foreach (var child in app_list.get_children ()) {
            app_list.remove (child);
        }

        var apps = AppInfo.get_all ();
        apps.sort ((a, b) => strcmp (
            a.get_display_name () ?? "",
            b.get_display_name () ?? ""));

        foreach (var app in apps) {
            if (!app.should_show ()) continue;
            var name = app.get_display_name () ?? "";
            if (!name.down ().contains (query)) continue;
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
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        // Header "Locations" -- clickable, toggles the revealer below
        var header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        header.margin = 4;
        header.get_style_context ().add_class ("manokwari-places-header");

        var arrow = new Gtk.Label ("▶");
        arrow.get_style_context ().add_class ("manokwari-places-arrow");
        header.pack_start (arrow, false, false, 4);

        var title = new Gtk.Label (_("Locations"));
        title.halign = Gtk.Align.START;
        header.pack_start (title, true, true, 0);

        var revealer = new Gtk.Revealer ();
        revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
        revealer.set_transition_duration (150);
        revealer.set_reveal_child (false);

        var header_btn = new Gtk.EventBox ();
        header_btn.add (header);
        header_btn.button_press_event.connect (() => {
            var expanded = !revealer.get_reveal_child ();
            revealer.set_reveal_child (expanded);
            arrow.set_text (expanded ? "▼" : "▶");
            return true;
        });
        container.pack_start (header_btn, false, false, 0);

        // Content inside the revealer
        var list = new Gtk.ListBox ();
        list.set_selection_mode (Gtk.SelectionMode.NONE);
        list.get_style_context ().add_class ("manokwari-places-list");
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

        revealer.add (list);
        container.pack_start (revealer, false, false, 0);

        return container;
    }

    Gtk.Widget build_session_buttons () {
        // Original's #sessions was a full-width bar (background spanning
        // the whole menu width) with a centered row of icons inside it.
        // So: an outer box carrying the background/style class, and a
        // separate inner box that actually holds the buttons, centered
        // within it.
        var bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bar.halign = Gtk.Align.FILL;
        bar.get_style_context ().add_class ("manokwari-sessions");

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
        bar.set_center_widget (box);

        var lock_btn = new Gtk.Button ();
        lock_btn.set_relief (Gtk.ReliefStyle.NONE);
        lock_btn.set_image (new Gtk.Image.from_icon_name ("system-lock-screen", Gtk.IconSize.LARGE_TOOLBAR));
        lock_btn.set_tooltip_text (_("Lock"));
        lock_btn.clicked.connect (() => {
            // Must dismiss the menu FIRST. PanelMenuBox grabs the keyboard
            // and pointer while open (Utils.grab, for Escape/click-outside
            // handling); light-locker needs those same grabs to lock. If
            // the menu still holds them, light-locker retries for ~10s,
            // fails with "Couldn't grab keyboard! (AlreadyGrabbed)" and
            // gives up ("Unable to lock the screen") -- confirmed in its
            // debug log on real hardware. That's what made Lock look like
            // it had a long delay: the first press silently failed
            // outright, and only a later press (with the menu by then
            // closed) actually worked.
            dismiss_requested ();
            // Small delay so the X11 ungrab actually takes effect before
            // light-locker tries to take over.
            Timeout.add (300, () => {
                Utils.lock_screen ();
                return false;
            });
        });
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

        return bar;
    }

    public void start () {
        // Browse mode is already shown by default (category_box in scroller).
        // Nothing to do here -- populate_apps() will switch to search mode
        // when the user types, and back to browse mode when they clear it.
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
