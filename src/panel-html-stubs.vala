// STUB (Milestone 1): placeholder for the WebKit-backed classes normally defined in
// panel-menu-html.vala / panel-desktop-html.vala. Those two files are excluded from
// the build (see src/meson.build) because they depend on webkitgtk-3.0, which no
// longer exists in any current distro. They are kept in the tree untouched as
// reference material for Milestone 3, where the real replacement gets decided
// (webkit2gtk-4.1 with WebKitUserContentManager, or a rewrite to native GTK widgets).
//
// These stand-ins just implement enough surface area (constructor + the methods
// called from panel-menu-box.vala / panel-desktop.vala) for the rest of the panel
// to compile, link, and show a visible placeholder instead of the real web view.

public class PanelMenuHTML : Gtk.Label {
    public PanelMenuHTML () {
        Object (label: "(menu view stub -- restored in Milestone 3)");
    }

    public void start () {}
    public void triggerShowAnimation () {}
    public void triggerHideAnimation () {}
    public bool handleEsc () { return false; }
}

public class PanelDesktopHTML : Gtk.Label {
    public PanelDesktopHTML () {
        Object (label: "(desktop view stub -- restored in Milestone 3)");
    }

    public void updateSize () {}
}
