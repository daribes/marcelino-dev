#!/usr/bin/env python
import sys
import pyjulius3
import Queue as queue
import time

# Initialize and try to connect
client = pyjulius3.Client('localhost', 10500)
try:
    client.connect()
except pyjulius3.ConnectionError:
    print 'Inicie el servidor julius primero...'
    sys.exit(1)

# Start listening to the server
client.start()
try:
    while 1:
        time.sleep(0.001)
        try:
            result = client.results.get(False)
        except queue.Empty:
            continue
        print repr(result)
except KeyboardInterrupt:
    print 'Saliendo...'
    client.disconnect()  # disconnect from julius
