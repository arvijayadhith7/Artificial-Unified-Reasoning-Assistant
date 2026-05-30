import os
import csv
import json
from http.server import SimpleHTTPRequestHandler, HTTPServer

PORT = 8080
DIRECTORY = 'website'
CSV_FILE = 'waitlist.csv'

class CustomHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Serve from website directory
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        if self.path == '/api/waitlist':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
                name = data.get('name', '')
                email = data.get('email', '')
                platform = data.get('platform', '')
                role = data.get('role', '')
                usecase = data.get('usecase', '')
                
                # Check if CSV file exists to write headers
                file_exists = os.path.isfile(CSV_FILE)
                
                with open(CSV_FILE, mode='a', newline='', encoding='utf-8') as f:
                    writer = csv.writer(f)
                    if not file_exists:
                        writer.writerow(['Name', 'Email', 'Platform', 'Role', 'UseCase'])
                    writer.writerow([name, email, platform, role, usecase])
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'success', 'message': 'Added to waitlist'}).encode('utf-8'))
                return
            except Exception as e:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'error', 'message': str(e)}).encode('utf-8'))
                return
        
        super().do_POST()

def run():
    print(f"Starting server on http://localhost:{PORT}")
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, CustomHandler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    print("Stopping server...")

if __name__ == '__main__':
    run()
