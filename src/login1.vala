// Milestone 3: minimal bindings for org.freedesktop.login1, replacing the
// org.gnome.SettingsDaemon.Power.Screen D-Bus property used for brightness.
// logind is systemd's own session/seat manager -- present on every systemd
// distro regardless of desktop environment, unlike GSD.

[DBus (name = "org.freedesktop.login1.Manager")]
interface Login1Manager : GLib.Object {
    [DBus (name = "GetSessionByPID")]
    public abstract ObjectPath get_session_by_pid (uint32 pid) throws DBusError, IOError;

    // Added for Milestone 3 session-manager rework (replaces
    // org.gnome.SessionManager.reboot()/shutdown()/can_shutdown()).
    [DBus (name = "Reboot")]
    public abstract void reboot (bool interactive) throws DBusError, IOError;
    [DBus (name = "PowerOff")]
    public abstract void power_off (bool interactive) throws DBusError, IOError;
    [DBus (name = "CanPowerOff")]
    public abstract string can_power_off () throws DBusError, IOError;
}

[DBus (name = "org.freedesktop.login1.Session")]
interface Login1Session : GLib.Object {
    [DBus (name = "SetBrightness")]
    public abstract void set_brightness (string subsystem, string name, uint32 brightness) throws DBusError, IOError;

    // Added for Milestone 5 Tahap 2 (Lock button fix). Calling this makes
    // logind emit its Lock signal on this session -- light-locker (a new
    // runtime dependency, see files/bin/manokwari-session) listens for
    // that signal and does the actual locking/unlocking, coordinating
    // with LightDM. Does nothing by itself without a locker daemon running.
    [DBus (name = "Lock")]
    public abstract void lock () throws DBusError, IOError;    
}
