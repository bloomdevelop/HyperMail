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
		fmt.eprintf("Missing .gresource, please generate by running \"just compile-resources\".")
		os.exit(1)
	}
	gio.resources_register(resource)

	// TODO: Create an helper to it can bundle at compile time
	// _, resource_err := helper.register_resource(#load("hypermail.gresource"))
    // if resource_err != nil {
    //     fmt.eprintf("HyperMail: %s\n", resource_err.message)
    //     glib.free(resource_err)
    //     os.exit(1)
    // }

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
