package pop3

import "../tls"
import "../utils"
import "core:fmt"
import "core:strconv"
import "core:strings"

Client :: struct {
	conn:    tls.Connection,
	pending: [dynamic]u8,
}

Error :: enum {
	None,
	Connect_Failed,
	IO_Failed,
	Bad_Response,
	Rejected,
	Invalid_Argument,
}

Response :: struct {
	lines:       [dynamic]string,
	status_line: string,
}

// TODO)) Ensure to make the port as number instead.
//
// Right now it uses hardcored port of 993, but there's some server that sets on a different
// ports. Which makes the hardcoded entirely useless. So we need to change it soon (-ish).
//
// TODO)) Small reminder to implement STARTTLS
connect :: proc(host: string, port := 995) -> (client: Client, err: Error) {
	conn, tls_err := tls.dial(host, port)
	if tls_err != .None {
		return {}, .Connect_Failed
	}
	client.conn = conn

	greeting, line_err := read_line(&client)
	if line_err != .None {
		disconnect(&client)
	}
	defer delete(greeting)
	if !strings.has_prefix(greeting, "+OK") {
		disconnect(&client)
		return {}, .Bad_Response
	}
	return client, .None
}

login :: proc(client: ^Client, user, password: string) -> Error {
	if strings.contains(user, "\r") || strings.contains(user, "\n") ||
		strings.contains(password, "\r") || strings.contains(password, "\n") {
		return .Invalid_Argument
	}

	if err := command_simple(client, fmt.tprintf("USER %s", user)); err != .None {
		return err
	}

	return command_simple(client, fmt.tprintf("PASS %s", password))
}

stat :: proc(client: ^Client) -> (count, size: int, err: Error) {
	line, line_err := command(client, "STAT")
	defer delete(line)
	if line_err != .None {
		return 0, 0, line_err
	}

	fields := strings.fields(line, context.temp_allocator)
	if len(fields) < 3 {
		return 0, 0, .Bad_Response
	}

	parsed_count, count_ok := strconv.parse_int(fields[1], 10)
	parsed_size, size_ok := strconv.parse_int(fields[2], 10)

	if !count_ok || !size_ok {
		return 0, 0, .Bad_Response
	}

	return int(parsed_count), int(parsed_size), .None
}

list :: proc(client: ^Client) -> (resp: Response, err: Error) {
	return command_multiline(client, "LIST")
}

uidl :: proc(client: ^Client) -> (resp: Response, err: Error) {
	return command_multiline(client, "UIDL")
}

capa :: proc(client: ^Client) -> (resp: Response, err: Error) {
	return command_multiline(client, "CAPA")
}

retr :: proc(client: ^Client, msg: int) -> (resp: Response, err: Error) {
	return command_multiline(client, fmt.tprintf("RETR %d", msg))
}

top :: proc(client: ^Client, msg, lines: int) -> (resp: Response, err: Error) {
	return command_multiline(client, fmt.tprintf("TOP %d %d", msg, lines))
}

dele :: proc(client: ^Client, msg: int) -> Error {
	return command_simple(client, fmt.tprintf("DELE %d", msg))
}

rset :: proc(client: ^Client) -> Error {
	return command_simple(client, "RSET")
}

quit :: proc(client: ^Client) {
	status, _ := command(client, "QUIT")
	delete(status)
	disconnect(client)
}

command :: proc(client: ^Client, cmd: string) -> (line: string, err: Error) {
	full := fmt.tprintf("%s\r\n", cmd)
	if _, werr := tls.write(&client.conn, transmute([]u8)full); werr != .None {
		return "", .IO_Failed
	}

	line, line_err := read_line(client)
	if line_err != .None {
		return "", .IO_Failed
	}

	switch{
	case strings.has_prefix(line, "+OK"):
		return line, .None
	case strings.has_prefix(line, "-ERR"):
		return line, .Rejected
	case:
		return line, .Bad_Response
	}
}

command_simple :: proc(client: ^Client, cmd: string) -> Error {
	status, err := command(client, cmd)
	delete(status)
	return err
}

command_multiline :: proc(client: ^Client, cmd: string) -> (resp: Response, err: Error) {
	status, status_err := command(client, cmd)
	resp.status_line = status
	if status_err != .None {
		return resp, status_err
	}

	for {
		line, line_err := read_line(client)
		if line_err != .None {
			response_destroy(&resp)
			return {}, .IO_Failed
		}
		if line == "." {
			delete(line)
			return resp, .None
		}
		if strings.has_prefix(line, ".") {
			unstuffed := strings.clone(line[1:])
			delete(line)
			line = unstuffed
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
}

read_line :: proc(client: ^Client, allocator := context.allocator) -> (line: string, err: Error) {
	for {
		if idx := utils.find_crlf(client.pending[:]); idx >= 0 {
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
