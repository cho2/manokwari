# Milestone 5 Tahap 3a-4: install only the Aurulent Sans OTF files from
# the original system/fonts/ directory. The rest (Arimo, Climacons,
# OpenSans, Trendex, ubuntu.woff, web fonts) are not installed -- they
# were only used by the now-removed WebKit frontend (system/menu.html,
# system/desktop.html). Aurulent Sans is the menu font we want to
# restore in the native GTK menu (Tahap 3a-4-ii/iii).
install_data(
    'AurulentSans-Bold.otf',
    'AurulentSans-BoldItalic.otf',
    'AurulentSans-Italic.otf',
    'AurulentSans-Regular.otf',
    install_dir: join_paths(get_option('datadir'), 'fonts', 'manokwari'),
)
