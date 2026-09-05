// Milestone 3: minimal bindings for org.freedesktop.login1, replacing the
// org.gnome.SettingsDaemon.Power.Screen D-Bus property used for brightness.
// logind is systemd's own session/seat manager -- present on every systemd
// distro regardless of desktop environment, unlike GSD.

[DBus (name = "org.freedesktop.login1.Manager")]
interface Login1Manager : GLib.Object {
    [DBus (name = "GetSessionByPID")]
    public abstract ObjectPath get_session_by_pid (uint32 pid) throws DBusError, IOError;
}

[DBus (name = "org.freedesktop.login1.Session")]
interface Login1Session : GLib.Object {
    [DBus (name = "SetBrightness")]
    public abstract void set_brightness (string subsystem, string name, uint32 brightness) throws DBusError, IOError;
}
