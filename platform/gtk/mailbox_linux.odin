package gtk_ui

import "core:fmt"

import adw "../../vendor/odin-gtk/adwaita"
import glib "../../vendor/odin-gtk/glib"
import gobj "../../vendor/odin-gtk/glib/gobject"
import gtk "../../vendor/odin-gtk/gtk"

// A mailbox as shown in the sidebar. Placeholder until the IMAP/POP3 layer
// supplies real accounts and folders.
Mailbox :: struct {
	name:      cstring,
	icon_name: cstring,
}

// Sample data so the skeleton has something to render.
mailboxes := [?]Mailbox {
	{name = "Inbox", icon_name = "mail-unread-symbolic"},
	{name = "Drafts", icon_name = "document-edit-symbolic"},
	{name = "Sent", icon_name = "mail-send-symbolic"},
	{name = "Archive", icon_name = "shoe-box-symbolic"},
	{name = "Junk", icon_name = "user-bookmarks-symbolic"},
	{name = "Trash", icon_name = "user-trash-symbolic"},
}

// Widgets from `ui/mailbox.ui` that the app keeps using after loading it.
Mailbox_UI :: struct {
	window:        ^gtk.Window,
	toast_overlay: ^adw.ToastOverlay,
	split_view:    ^adw.NavigationSplitView,
}

// Single-window app, so this lives for the whole run and callbacks can safely
// use a pointer to it as user data.
mailbox_ui: Mailbox_UI

// Builds the main window from `ui/mailbox.ui`. Returns nil if the UI file
// cannot be loaded.
setup_mailbox_ui :: proc(app: ^gtk.Application) -> ^gtk.Window {
	// The path is baked in at compile time for now; release builds should embed
	// the file (or a compiled .gresource) instead of reading from the source tree.
	builder := gtk.builder_new_from_file(#directory + "ui/mailbox.ui")
	if builder == nil {
		fmt.eprintln("HyperMail: could not load platform/ui/mailbox.ui")
		return nil
	}
	defer gobj.object_unref(builder)

	window_obj := gtk.builder_get_object(builder, "window")
	split_view := adw.NAVIGATION_SPLIT_VIEW(gtk.builder_get_object(builder, "split_view"))
	toast_overlay := adw.TOAST_OVERLAY(gtk.builder_get_object(builder, "toast_overlay"))
	mailbox_list := gtk.LIST_BOX(gtk.builder_get_object(builder, "mailbox_list"))
	compose_button := gtk.BUTTON(gtk.builder_get_object(builder, "compose_button"))

	if window_obj == nil ||
	   split_view == nil ||
	   toast_overlay == nil ||
	   mailbox_list == nil ||
	   compose_button == nil {
		fmt.eprintln("HyperMail: mailbox.ui is missing expected widgets")
		return nil
	}

	// The window comes from the builder rather than `adw.application_window_new`,
	// so it has to be attached to the application by hand. This also makes
	// `gtk_application_get_active_window` in `on_activate` find it again.
	window := gtk.WINDOW(window_obj)
	gtk.window_set_application(window, app)

	mailbox_ui = {
		window        = window,
		toast_overlay = toast_overlay,
		split_view    = split_view,
	}

	for mailbox in mailboxes {
		gtk.list_box_append(mailbox_list, mailbox_row(mailbox))
	}

	gobj.signal_connect(compose_button, "clicked", on_compose_clicked, &mailbox_ui)
	gobj.signal_connect(mailbox_list, "row-activated", on_mailbox_activated, &mailbox_ui)

	return window
}

@(private = "file")
mailbox_row :: proc(mailbox: Mailbox) -> ^gtk.Widget {
	content := gtk.box_new(.HORIZONTAL, 12)
	gtk.widget_set_margin_top(content, 12)
	gtk.widget_set_margin_bottom(content, 12)
	gtk.widget_set_margin_start(content, 12)
	gtk.widget_set_margin_end(content, 12)
	gtk.box_append(gtk.BOX(content), gtk.image_new_from_icon_name(mailbox.icon_name))
	gtk.box_append(gtk.BOX(content), gtk.label_new(mailbox.name))

	row := gtk.LIST_BOX_ROW(gtk.list_box_row_new())
	gtk.list_box_row_set_child(row, content)

	return gtk.WIDGET(row)
}

@(private = "file")
on_compose_clicked :: proc "c" (button: ^gtk.Button, user_data: glib.pointer) {
	ui := cast(^Mailbox_UI)user_data
	adw.toast_overlay_add_toast(
		ui.toast_overlay,
		adw.toast_new("The composer is not implemented yet"),
	)
}

@(private = "file")
on_mailbox_activated :: proc "c" (list: ^gtk.ListBox, row: ^gtk.ListBoxRow, user_data: glib.pointer) {
	ui := cast(^Mailbox_UI)user_data

	// The content pane is where the message list and viewer will live. On
	// narrow windows, picking a mailbox should bring that pane into view.
	adw.navigation_split_view_set_show_content(ui.split_view, true)
}
