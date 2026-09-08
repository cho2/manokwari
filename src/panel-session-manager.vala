using Gtk;
// STUB (Milestone 1): `using JSCore;` removed. JS-bridge block below guarded out.

// Milestone 3: org.gnome.SessionManager / .ClientPrivate removed along with
// gnome-session itself. Manokwari no longer runs inside a gnome-session --
// see files/bin/manokwari-session, which execs Openbox directly (picom
// and manokwari itself started via Openbox's own autostart mechanism).
//
// reboot()/shutdown()/can_shutdown() now go through org.freedesktop.login1
// (systemd-logind) instead -- same freedesktop-standard mechanism already
// used for brightness (login1.vala). logout() has no systemd/logind
// equivalent (logind manages sessions, not desktop "log out of the GUI"
// semantics) -- it uses Openbox's own documented exit mechanism instead
// ("openbox --exit" asks a running Openbox instance to shut down, which
// ends the X session since Openbox is the session's foreground process).

public class PanelSessionManager {
    static PanelSessionManager instance = null;
    private Login1Manager login1 = null;

    public static PanelSessionManager getInstance () {
        if (instance == null) {
            instance = new PanelSessionManager ();
        }

        return instance;
    }

    private PanelSessionManager () {
        try {
            login1 = Bus.get_proxy_sync (BusType.SYSTEM,
                                          "org.freedesktop.login1", "/org/freedesktop/login1");
        } catch (Error e) {
            stderr.printf ("Unable to connect to logind: %s\n", e.message);
        }
    }

    public async void logout () {
        try {
            Process.spawn_command_line_async ("openbox --exit");
        } catch (SpawnError e) {
            stderr.printf ("Unable to exit Openbox: %s\n", e.message);
        }
    }

    public async void reboot () {
        if (login1 == null) {
            return;
        }
        try {
            login1.reboot (true);
        } catch (Error e) {
            stderr.printf ("Unable to reboot: %s\n", e.message);
        }
    }

    public async void shutdown () {
        if (login1 == null) {
            return;
        }
        try {
            login1.power_off (true);
        } catch (Error e) {
            stderr.printf ("Unable to shutdown: %s\n", e.message);
        }
    }

    public bool can_shutdown () {
        if (login1 == null) {
            return false;
        }
        try {
            // CanPowerOff() returns "yes" / "no" / "challenge" (challenge
            // means it's possible but needs authentication) per logind's
            // convention -- anything other than a plain "no" counts as
            // available here.
            return login1.can_power_off () != "no";
        } catch (Error e) {
            stderr.printf ("Unable to query shutdown availability: %s\n", e.message);
            return false;
        }
    }

    /* STUB (Milestone 1) -- begin JSCore bridge block
    public static JSCore.Object js_constructor (Context ctx,
            JSCore.Object constructor,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

        exception = null;
        var c = new Class (js_class);
        var o = new JSCore.Object (ctx, c, null);
        var s = new String.with_utf8_c_string ("canShutdown");
        var f = new JSCore.Object.function_with_callback (ctx, s, js_can_shutdown);
        o.set_property (ctx, s, f, 0, null);

        s = new String.with_utf8_c_string ("logout");
        f = new JSCore.Object.function_with_callback (ctx, s, js_logout);
        o.set_property (ctx, s, f, 0, null);

        s = new String.with_utf8_c_string ("reboot");
        f = new JSCore.Object.function_with_callback (ctx, s, js_reboot);
        o.set_property (ctx, s, f, 0, null);

        s = new String.with_utf8_c_string ("shutdown");
        f = new JSCore.Object.function_with_callback (ctx, s, js_shutdown);
        o.set_property (ctx, s, f, 0, null);

        PanelSessionManager* i = PanelSessionManager.getInstance ();
        o.set_private (i);
        return o;
    }

    public static JSCore.Value js_can_shutdown (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,

            out JSCore.Value exception) {

        exception = null;
        var i = thisObject.get_private() as PanelSessionManager; 
        if (i != null) {
            return new JSCore.Value.boolean (ctx, i.can_shutdown()); 
        }
        return new JSCore.Value.undefined (ctx);
    }

    public static JSCore.Value js_shutdown (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,

            out JSCore.Value exception) {

        exception = null;
        var i = thisObject.get_private() as PanelSessionManager; 
        if (i != null) {
            i.shutdown.begin();
        }
        return new JSCore.Value.undefined (ctx);
    }

    public static JSCore.Value js_reboot (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,

            out JSCore.Value exception) {

        exception = null;
        var i = thisObject.get_private() as PanelSessionManager; 
        if (i != null) {
            i.reboot.begin();
        }
        return new JSCore.Value.undefined (ctx);
    }


    public static JSCore.Value js_logout (Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,

            out JSCore.Value exception) {

        exception = null;
        var i = thisObject.get_private() as PanelSessionManager; 
        if (i != null) {
            i.logout.begin();
        }
        return new JSCore.Value.undefined (ctx);
    }


    const ClassDefinition js_class = {
        0,
        ClassAttribute.None,
        "SessionManager",
        null,

        null,
        null,

        null,
        null,

        null,
        null,
        null,
        null,

        null,
        null,
        js_constructor,
        null,
        null
    };


    public static void setup_js_class (GlobalContext context) {
        var c = new Class (js_class);
        var o = new JSCore.Object (context, c, context);
        var g = context.get_global_object ();
        var s = new String.with_utf8_c_string ("SessionManager");
        g.set_property (context, s, o, PropertyAttribute.None, null);
    }
    */ // STUB (Milestone 1) -- end JSCore bridge block

}
