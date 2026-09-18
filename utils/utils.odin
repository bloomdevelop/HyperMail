package utils

// find_crlf finds the index of the first CRLF sequence in the given data.
find_crlf :: proc(data: []u8) -> int {
	for i in 0 ..< len(data) - 1 {
		if data[i] == '\r' && data[i + 1] == '\n' {
			return i
		}
	}

	return -1
}
