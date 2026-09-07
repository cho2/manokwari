manokwari_panel_sources = [
    'main.vala',
    'panel-abstract-window.vala',
    'panel-window.vala',
    'panel-menu-box.vala',
    'panel-menu-content.vala',
    'panel-tray.vala',
    'panel-scrollable-content.vala',
    'panel-animated-adjustment.vala',
    'panel-clock.vala',
    'panel-places.vala',
    'panel-screen.vala',
    'utils.vala',
    'panel-hotkey.vala',
    'panel-session-manager.vala',
    # 'panel-menu-html.vala',      # STUB (Milestone 1): needs WebKit, see Milestone 3
    'panel-desktop-native.vala',
    'panel-menu-native.vala',
    'xdg-data.vala',
    'panel-user.vala',
    'panel-desktop.vala',
    # 'panel-desktop-html.vala',   # STUB (Milestone 1): needs WebKit, see Milestone 3
    'panel-desktop-data.vala',
    'panel-calendar.vala',
    'animated-property.vala',
    'panel-shell.vala',
    'panel-socket.vala',
    'login1.vala',
]

manokwari_panel_deps = [
    dep_gtk3,
    dep_glib,
    dep_atk,
    dep_x11,
    dep_gee,
    dep_cairo,
    dep_libnotify,
    dep_libwnck,
]

manokwari_vapi = join_paths(meson.source_root(), 'vapi')

executable(
    'manokwari', manokwari_panel_sources,
    dependencies: manokwari_panel_deps,
    include_directories: extra_includes,
    vala_args: [
        '--pkg', 'config',
        '--pkg', 'posix',
        '--vapidir', manokwari_vapi,
        '--pkg', 'atk',
        '--pkg', 'x11',
        '--pkg', 'gdk-x11-3.0',
        '--pkg', 'gee-0.8',
        '--pkg', 'cairo',
        '--pkg', 'gtk+-3.0',
        '--pkg', 'gio-unix-2.0',
        '--pkg', 'gdk-3.0',
        '--pkg', 'libwnck-3.0',
        '--pkg', 'libnotify',
    ],
    c_args: [
        '-DGMENU_I_KNOW_THIS_IS_UNSTABLE',
        '-DWNCK_I_KNOW_THIS_IS_UNSTABLE',
    ],
    install: true,
)
