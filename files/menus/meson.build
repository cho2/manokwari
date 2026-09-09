# Milestone 4: stopped installing manokwari-applications.menu. Nothing in
# this project parses it anymore -- the native app menu (Fase 1,
# panel-menu-native.vala) uses GLib.AppInfo.get_all() directly, not the
# freedesktop Desktop Menu Spec category hierarchy this file describes.
# It also referenced two submenus whose supporting files don't exist
# anywhere in this repo: "Geo.BlankOn" (custom Peta category, needs a
# missing Peta.directory) and "Debian" (needs a missing debian-menu.menu
# merge file) -- both clearly leftover from BlankOn's Debian-based
# original, not applicable to an openSUSE-targeting independent fork.
#
# The file itself is kept in the tree (not deleted) as reference in case
# category-based menu parsing is ever reconsidered.
