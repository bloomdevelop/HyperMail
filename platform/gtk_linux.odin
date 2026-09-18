package platform

import "core:os"
import gtk "../vendor/odin-gtk/gtk"
import gio "../vendor/odin-gtk/glib/gio"
import gobj "../vendor/odin-gtk/glib/gobject"

on_activate :: proc "c" (app: ^gtk.Application, user_data: rawptr) {
	window := gtk.WINDOW(gtk.application_window_new(app))
	gtk.window_set_title(window, "SuperMail")
	gtk.window_set_default_size(window, 400, 300)

	box := gtk.box_new(.VERTICAL, 10)

	gtk.window_set_child(window, box)
	gtk.widget_show(gtk.WIDGET(window))
}

run :: proc() {
	app := gtk.application_new("io.github.bloomdevelop.supermail", .APPLICATION_DEFAULT_FLAGS)

	gobj.signal_connect(app, "activate", on_activate)

	status := gio.application_run(app)
	gobj.object_unref(app)
	os.exit(int(status))
}
