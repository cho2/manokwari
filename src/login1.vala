[DBus (name = "org.freedesktop.login1.Manager")]
interface Login1Manager : GLib.Object {
    [DBus (name = "GetSessionByPID")]
    public abstract ObjectPath get_session_by_pid (uint32 pid) throws DBusError, IOError;

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

    [DBus (name = "Lock")]
    public abstract void lock () throws DBusError, IOError;    
}
