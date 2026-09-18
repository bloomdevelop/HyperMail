package platform

import NS "core:sys/darwin/Foundation"

run :: proc() {
	app := NS.Application.sharedApplication()
	app->setActivationPolicy(.Regular)

	delegate := NS.application_delegate_register_and_alloc({
		applicationShouldTerminateAfterLastWindowClosed = proc(^NS.Application) -> NS.BOOL {
			return true
		}
	}, "AppDelegate", context)
	app->setDelegate(delegate)

	frame := NS.Rect{{0,0}, {400, 300}}
	wnd := NS.Window.alloc()
	wnd->initWithContentRect(frame, {
		.Titled,
		.Closable,
		.Miniaturizable,
		.Resizable,
	}, .Buffered, false)
	wnd->setTitle(NS.AT("HyperMail"))
	wnd->center()
	wnd->makeKeyAndOrderFront(nil)

	app->run()
}
