package imap

import "core:fmt"
import "core:strings"
import "../tls"

Client :: struct {
	conn: tls.Connection,
	tag_counter: int,
	pending: [dynamic]u8 // These are received bytes not yet consumed as lines
}

Error :: enum {
	None,
	Connect_Failed,
	IO_Failed,
	Bad_Response,
	No, // operation refused
	Bad, // protocol error
}

Response :: struct {
	lines: [dynamic]string,
	status_line: string,
}

// TODO: Ensure to make the port as number instead.
//
// Right now it uses hardcored port of 993, but there's some server that sets on a different
// ports. Which makes the hardcoded entirely useless. So we need to change it soon (-ish).
connect :: proc(host: string, port := 993) -> (client: Client, err: Error) {
	conn, tls_err := tls.dial(host, port)
	if tls_err != .None {
		return {}, .Connect_Failed
	}
	client.conn = conn

	greeting, line_err := read_line(&client)
	if line_err != .None {
		disconnect(&client)
		return {}, .IO_Failed
	}
	defer delete(greeting)
	if !strings.has_prefix(greeting, "* OK") {
		disconnect(&client)
		return {}, .Bad_Response
	}
	return client, .None
}

command :: proc(client: ^Client, cmd: string) -> (resp: Response, err: Error) {
	client.tag_counter += 1
	tag := fmt.tprintf("A%03d", client.tag_counter)

	full := fmt.tprintf("%s %s\r\n", tag, cmd)
	if _, werr := tls.write(&client.conn, transmute([]u8)full); werr != .None {
		return {}, .IO_Failed
	}

	for {
		line, lerr := read_line(client)
		if lerr != .None {
			response_destroy(&resp)
			return {}, .IO_Failed
		}
		if strings.has_prefix(line, tag) {
			resp.status_line = line
			rest := strings.trim_left_space(line[len(tag):])

			switch {
			case strings.has_prefix(rest, "OK"):
				return resp, .None
			case strings.has_prefix(rest, "NO"):
				return resp, .No
			case:
				return resp, .Bad
			}
		}
		append(&resp.lines, line)
	}
}

response_destroy :: proc(resp: ^Response) {
	for line in resp.lines {
		delete(line)
	}
	delete(resp.lines)
	delete(resp.status_line)

	resp^ = {}
}

login :: proc(client: ^Client, user, password: string) -> Error {
	resp, err := command(client, fmt.tprintf("LOGIN \"%s\" \"%s\"", user, password))
	response_destroy(&resp)
	return err
}

select_mailbox :: proc(client: ^Client, mailbox := "INBOX") -> (Response, Error) {
	return command(client, fmt.tprintf("SELECT \"%s\"", mailbox))
}

list_mailboxes :: proc(client: ^Client) -> (Response, Error) {
	return command(client, "LIST \"\" \"*\"")
}

logout :: proc(client: ^Client) {
	resp, _ := command(client, "LOGOUT")
	response_destroy(&resp)
	disconnect(client)
}

read_line :: proc(client: ^Client, allocator := context.allocator) -> (line: string, err: Error) {
	for {
		if idx := find_crlf(client.pending[:]); idx >= 0 {
			line = strings.clone(string(client.pending[:idx]), allocator)
			remove_range(&client.pending, 0, idx + 2)
			return line, .None
		}

		buf: [4096]u8
		n, read_err := tls.read(&client.conn, buf[:])
		if read_err != .None {
			return "", .IO_Failed
		}
		append(&client.pending, ..buf[:n])
	}
}

disconnect :: proc(client: ^Client) {
	tls.close(&client.conn)
	delete(client.pending)
	client.pending = nil
}

@(private)
find_crlf :: proc(data: []u8) -> int {
	for i in 0 ..< len(data) - 1 {
		if data[i] == '\r' && data[i + 1] == '\n' {
			return i
		}
	}
	return -1
}
