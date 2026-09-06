// STUB (Milestone 1, still applies to PanelDesktopHTML only): PanelMenuHTML
// got its real native implementation in panel-menu-native.vala (Milestone 3,
// Fase 1). PanelDesktopHTML is Fase 2 (desktop sidebar/bevel) -- per project
// decision, everything there is dropped except the clock, not yet built.

public class PanelDesktopHTML : Gtk.Label {
    public PanelDesktopHTML () {
        Object (label: "(desktop view stub -- Fase 2, clock only, not yet built)");
    }

    public void updateSize () {}
}
