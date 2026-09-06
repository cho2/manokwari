# Inspired by https://github.com/budgie-desktop/budgie-desktop/blob/master/meson.build

project(
    'manokwari',
    ['c', 'vala'],
    version: '1.0.0',
    license: [
        'GPL-2.0',
    ],
    default_options: [
        'c_std=c11',
    ],
    meson_version: '>= 0.37',
)

am_cflags = [
    '-fstack-protector',
    '-pedantic',
    '-Wstrict-prototypes',
    '-Wundef',
    '-Werror-implicit-function-declaration',
    '-Wformat',
    '-Wformat-security',
    '-Werror=format-security',
    '-Wconversion',
    '-Wunused-variable',
    '-Wunreachable-code',
    '-Wall',
    '-W',
]

add_global_arguments(am_cflags, language: 'c')

gnome_minimum_version = '>= 3.0.8'

dep_glib = dependency('glib-2.0', version: '>= 2.12.0')
dep_gtk3 = dependency('gtk+-3.0', version: gnome_minimum_version)
dep_atk = dependency('atk', version: '>= 2.0.0')
dep_gee = dependency('gee-0.8', version: '>= 0.20.0')
dep_cairo = dependency('cairo', version: '>= 1.10.2')
# STUB (Milestone 3): dependency('libgnome-menu-3.0', ...) removed -- its only
# consumer (GMenu.Tree in xdg-data.vala) is now guarded out, see that file.
dep_libwnck = dependency('libwnck-3.0', version: '>= 3.0.0')
# STUB (Milestone 1): unique-3.0 and webkitgtk-3.0 no longer exist in any current
# distro. Real replacements land in Milestone 3 (unique -> GApplication, webkit ->
# either webkit2gtk-4.1 or native GTK widgets). Removed here so the project can
# configure/compile again; corresponding code is guarded out below.
dep_x11 = dependency('x11', version: '>= 1.6.0')
dep_libnotify = dependency('libnotify', version: '>= 0.7.6')
# Milestone 3: brightness (src/panel-window.vala) no longer needs this -- it
# now goes through org.freedesktop.login1 + sysfs. Kept here only because
# files/sessions/meson.build still uses dep_gsd.version() to pick which GSD
# components to require in the session file. That's the still-untouched
# "session manager + mutter requirement" item from INVENTORY.md/ROADMAP.md,
# not part of this change.
dep_gsd = dependency('gnome-settings-daemon', version: gnome_minimum_version)

# Create config.h
cdata = configuration_data()

# Inspired by https://github.com/GNOME/recipes/blob/master/meson.build
package_version = meson.project_version()
cdata.set_quoted('PACKAGE_VERSION', package_version)

# Make gettext work
cdata.set_quoted('GETTEXT_PACKAGE', meson.project_name())
add_global_arguments('-DGETTEXT_PACKAGE="manokwari"', language: 'c')

# Globals that we need
prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
libdir = join_paths(prefix, get_option('libdir'))
confdir = join_paths(prefix, get_option('sysconfdir'))
datadir = join_paths(prefix, get_option('datadir'))
localedir = join_paths(prefix, get_option('localedir'))
podir = join_paths(meson.source_root(), 'po')

manokwari_system_path = join_paths(libdir, 'manokwari', 'system')
manokwari_session_path = join_paths(datadir, 'gnome-session', 'sessions')
manokwari_xsession_path = join_paths(datadir, 'xsessions')


# Handle i18n on the .desktop file
# Originally stolem from TingPing:
# https://github.com/vinszent/gnome-twitch/blob/master/data/meson.build
# Later changed to use intltool as we use _Key style files
intltool = find_program('intltool-merge')

cdata.set_quoted('SYSTEM_PATH', manokwari_system_path)
cdata.set_quoted('SESSIONS_PATH', manokwari_session_path)
cdata.set_quoted('XSESSIONS_PATH', manokwari_xsession_path)
cdata.set_quoted('BIN_PATH', bindir)
cdata.set_quoted('LOCALEDIR', localedir)


# Write config.h
configure_file(
    output: 'config.h',
    configuration: cdata,
)

extra_includes = [
    include_directories('.'),
]

subdir('po')
subdir('src')
subdir('system')
subdir('data')
subdir('files')
