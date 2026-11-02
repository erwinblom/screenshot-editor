"""Offline Screenshot Editor launcher. Python 3.9+; no packages."""
import argparse
import functools
import http.server
from pathlib import Path
import webbrowser
ROOT = Path(__file__).resolve().parent
PUBLIC = {'/', '/index.html', '/web/app.js', '/web/style.css', '/Resources/FMT-tool-icon.png', '/README.md'}
class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        super().end_headers()
    def list_directory(self, path):
        self.send_error(404)
    def send_head(self):
        if self.headers.get('Host') not in ('127.0.0.1:48763', 'localhost:48763'):
            self.send_error(403)
            return
        if self.path.split('?', 1)[0] not in PUBLIC:
            self.send_error(404)
            return
        return super().send_head()
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Start Screenshot Editor op deze computer.')
    parser.add_argument('--no-browser', action='store_true')
    args = parser.parse_args()
    try:
        server = http.server.ThreadingHTTPServer(('127.0.0.1', 48763), functools.partial(Handler, directory=str(ROOT)))
    except OSError:
        raise SystemExit('Poort 48763 is bezet. Sluit een eerdere Screenshot-startterminal en probeer opnieuw.')
    print('Screenshot Editor: http://127.0.0.1:48763\nSluit dit venster of druk Ctrl+C om te stoppen.', flush=True)
    if not args.no_browser:
        webbrowser.open('http://127.0.0.1:48763')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
