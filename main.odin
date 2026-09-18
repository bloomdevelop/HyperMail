package main

import "core:os"
import "core:fmt"
import "platform"

main :: proc() {
	when ODIN_OS == .Darwin || ODIN_OS == .Linux {
		platform.run()
	} else {
		fmt.eprintln("This operation system ({}) is not supported, please file an issue.", ODIN_OS)
		os.exit(1)
	}
}
