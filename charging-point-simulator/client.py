import websocket
import time
import sys
import os
import ssl

url = os.environ.get("BACKEND_URL")

def on_message(ws, message):
    print(message)

def on_error(ws, error):
    print(error)

def on_close(ws):
    print("### closed ###")

#Charging point is sending "Hello" to backend every 5sec
def on_open(ws):
    while True:
        time.sleep(5)
        ws.send("Hello")
    time.sleep(1)
    ws.close()

if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("wss://"+url,
                              on_message = on_message,
                              on_error = on_error,
                              on_close = on_close)
    ws.on_open = on_open
    ws.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE})