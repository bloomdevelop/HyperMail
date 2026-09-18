package tls

import "core:c"
import "core:net"
import "core:strings"

foreign import lib {"system:ssl", "system:openssl"}

SSL_METHOD :: struct {}
SSL_CTX :: struct {}
SSL :: struct {}

@(default_calling_convention = "c")
foreign lib {
	TLS_client_method :: proc() -> ^SSL_METHOD ---
	SSL_CTX_new :: proc(method: ^SSL_METHOD) -> ^SSL_CTX ---
	SSL_CTX_free :: proc(ctx: ^SSL_CTX) ---
	SSL_CTX_set_verify :: proc(ctx: ^SSL_CTX, mode: c.int, callback: rawptr) ---
	SSL_CTX_set_default_verify_paths :: proc(ctx: ^SSL_CTX) -> c.int ---
	SSL_new :: proc(ssl_ctx: ^SSL_CTX) -> ^SSL ---
	SSL_free :: proc(ssl: ^SSL) ---
	SSL_set_fd :: proc(ssl: ^SSL, fd: c.int) -> c.int ---
	SSL_connect :: proc(ssl: ^SSL) -> c.int ---
	SSL_read :: proc(ssl: ^SSL, buf: rawptr, num: c.int) -> c.int ---
	SSL_write :: proc(ssl: ^SSL, buf: rawptr, num: c.int) -> c.int ---
	SSL_shutdown :: proc(ssl: ^SSL) -> c.int ---
	SSL_ctrl :: proc(ssl: ^SSL, cmd: c.int, larg: c.long, parg: rawptr) -> c.long ---
	SSL_set1_host :: proc(ssl: ^SSL, hostname: cstring) -> c.int ---
}

SSL_CTRL_SET_TLSEXT_HOSTNAME :: 55
TLSEXT_NAMETYPE_host_name :: 0
SSL_VERIFY_PEER :: 0x01

Connection :: struct {
	socket: net.TCP_Socket,
	ctx: ^SSL_CTX,
	ssl: ^SSL
}

Error :: enum {
	None,
	Dial_Failed,
	Context_Failed,
	Handshake_Failed,
	Read_Failed,
	Write_Failed,
}

dial :: proc(hostname: string, port: int) -> (conn: Connection, err: Error) {
	socket, net_err := net.dial_tcp(hostname, port)
	if net_err != nil {
		return {}, .Dial_Failed
	}
	conn.socket = socket

	conn.ctx = SSL_CTX_new(TLS_client_method())
	if conn.ctx == nil {
		net.close(socket)
		return {}, .Context_Failed
	}
	SSL_CTX_set_verify(conn.ctx, SSL_VERIFY_PEER, nil)
	SSL_CTX_set_default_verify_paths(conn.ctx)

	conn.ssl = SSL_new(conn.ctx)
	chost := strings.clone_to_cstring(hostname, context.temp_allocator)

	// SNI + cerficate hostname verification
	SSL_ctrl(conn.ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, rawptr(chost))
	SSL_set1_host(conn.ssl, chost)
	SSL_set_fd(conn.ssl, c.int(socket))

	if SSL_connect(conn.ssl) != 1 {
		close(&conn)
		return {}, .Handshake_Failed
	}
	return conn, .None
}

read :: proc(conn: ^Connection, buf: []u8) -> (n: int, err: Error) {
	res := SSL_read(conn.ssl, raw_data(buf), c.int(len(buf)))
	if res < 0 {
		return 0, .Read_Failed
	}
	return int(res), .None
}

write :: proc(conn: ^Connection, data: []u8) -> (n: int, err: Error) {
	total := 0
	for total < len(data) {
		res := SSL_write(conn.ssl, raw_data(data[total:]), c.int(len(data) - total))
		if res <= 0 {
			return total, .Write_Failed
		}
		total += int(res)
	}
	return total, .None
}

close :: proc(conn: ^Connection) {
	if conn.ssl != nil {
		SSL_shutdown(conn.ssl)
		SSL_free(conn.ssl)
		conn.ssl = nil
	}
	if conn.ctx != nil {
		SSL_CTX_free(conn.ctx)
		conn.ctx = nil
	}
	net.close(conn.socket)
}
