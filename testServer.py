from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import json
import time
import threading
import random
from datetime import datetime, timedelta

# Just a local host server for the test purposes on the computer of the watchface

# Initialize state
data = []
last_sgv = 120  # start around 120 mg/dL
last_time = int(time.time() * 1000)

unitshint = "mgdl"

DIRECTIONS = ["Flat", "FortyFiveUp", "FortyFiveDown", "SingleUp", "SingleDown", "DoubleUp", "DoubleDown"]

def realistic_direction(delta):
    if abs(delta) < 2:
        return "Flat"
    elif 2 <= delta < 5:
        return "FortyFiveUp" if delta > 0 else "FortyFiveDown"
    elif 5 <= delta < 10:
        return "SingleUp" if delta > 0 else "SingleDown"
    else:
        return "DoubleUp" if delta > 0 else "DoubleDown"

def generate_new_entry(prev_sgv, new_time):
    # Random delta to simulate sugar changes
    delta = round(random.uniform(-10, 10), 3)
    new_sgv = max(40, min(prev_sgv + delta, 400))  # realistic glucose range

    direction = realistic_direction(delta)
    # new_time = prev_time + 5 * 60 * 1000  # add 5 minutes in ms

    entry = {
        "date": new_time,
        "sgv": int(new_sgv),
        "delta": delta,
        "direction": direction,
        "noise": 1
    }
    return entry, new_sgv, new_time

def seed_initial_data():
    global data, last_sgv, last_time
    now = int(time.time() * 1000)
    last_time = now - (60 * 5 * 60 * 1000)  # 60 entries back, 5 minutes each
    skip_at = random.randint(15, 45)  # insert a random gap
    for i in range(60):
        if i == skip_at:
            last_time += 15 * 60 * 1000  # skip 15 minutes
            i += 3
        entry, last_sgv, last_time = generate_new_entry(last_sgv, last_time + 5 * 60 * 1000)
        data.insert(0, entry)

def updater_thread():
    global data, last_sgv, last_time
    while True:
        # Occasionally skip a data point (simulate 15-minute loss)
        if random.random() < 0.05:
            last_time += 15 * 60 * 1000
            time.sleep(900)  # sleep for 15 minutes
        else:
            entry, last_sgv, last_time = generate_new_entry(last_sgv, int(time.time() * 1000))
            entry["units_hint"] = unitshint
            data.insert(0, entry)
            time.sleep(300)  # sleep for 5 minutes
        # Keep data size manageable
        if len(data) > 1000:
            data = data[:1000]

class JSONHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/sgv.json'):
            try:
                query = parse_qs(urlparse(self.path).query)
                count = int(query.get('count', [len(data)])[0])
                count = min(count, len(data))

                response_data = json.loads(json.dumps(data[:count]))  # deep copy
                if response_data:
                    response_data[0]["units_hint"] = unitshint

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(response_data).encode('utf-8'))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Server error: {e}".encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def run_server():
    server_address = ('127.0.0.1', 17580)
    httpd = HTTPServer(server_address, JSONHandler)
    print("Starting glucose mock server at http://127.0.0.1:17580/sgv.json")
    httpd.serve_forever()

if __name__ == "__main__":
    seed_initial_data()
    threading.Thread(target=updater_thread, daemon=True).start()
    run_server()
