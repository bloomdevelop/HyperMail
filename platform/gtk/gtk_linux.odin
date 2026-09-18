package gtk_ui

import "base:runtime"
import "core:fmt"
import "core:os"

import adw "../../vendor/odin-gtk/adwaita"
import gio "../../vendor/odin-gtk/glib/gio"
import gobj "../../vendor/odin-gtk/glib/gobject"
import gtk "../../vendor/odin-gtk/gtk"

RESOURCE_BASE :: "/io/github/bloomdevelop/HyperMail"
ICONS_PATH :: RESOURCE_BASE + "/data/icons"

on_activate :: proc "c" (app: ^gtk.Application, user_data: rawptr) {
	context = runtime.default_context()

	// `activate` can fire again when the app is launched a second time; reuse
	// the existing window instead of building a new one.
	window := gtk.application_get_active_window(app)
	if window == nil {
		window = setup_mailbox_ui(app)
	}
	if window == nil {
		return
	}
	gtk.window_present(window)
}

run :: proc() {
	resource := gio.resource_load(#directory + "hypermail.gresource", nil)
	if resource == nil {
		fmt.eprintf("Missing .gresource, please generate it.")
	}
	gio.resources_register(resource)

	gtk.init()
	gtk.icon_theme_add_resource_path(
		gtk.icon_theme_get_for_display(gtk.gdk_display_get_default()),
		ICONS_PATH
	)

	app := adw.application_new("io.github.bloomdevelop.HyperMail", .APPLICATION_DEFAULT_FLAGS)

	gobj.signal_connect(app, "activate", on_activate)

	status := gio.application_run(app)
	gobj.object_unref(app)
	os.exit(int(status))
}
