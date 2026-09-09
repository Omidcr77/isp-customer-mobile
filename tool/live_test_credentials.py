"""One-use loopback credential handoff for an explicitly authorized device test.

Credentials are read with terminal echo disabled, kept in memory and served once.
No request/response logging. Never expose this service beyond loopback.
"""
import getpass
import json
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handoff(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path != '/credentials':
            self.send_error(404)
            return
        payload = self.server.payload
        self.server.payload = b''
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


if __name__ == '__main__':
    with HTTPServer(('127.0.0.1', 8767), Handoff) as server:
        server.timeout = 900
        server.payload = json.dumps({
            'username': getpass.getpass('Test username (hidden): '),
            'password': getpass.getpass('Test password (hidden): '),
        }).encode()
        print('One-use credential handoff ready on loopback.', flush=True)
        server.handle_request()
        server.payload = b''
