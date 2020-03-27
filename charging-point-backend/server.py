from websocket_server import WebsocketServer
import subprocess

#Run healthcheck as a separate REST server
subprocess.Popen(["python","health_check.py"])

# Called for every charging point connecting (after handshake)
def new_client(client, server):
	print("New charging point connected and was given id %d" % client['id'])

# Called for every charging point disconnecting
def client_left(client, server):
	print("Charging point (%d) disconnected" % client['id'])

# Called when a charging point sends a message
def message_received(client, server, message):
	if len(message) > 200:
		message = message[:200]+'..'
	print("Charging point (%d) said: %s" % (client['id'], message))


PORT=80
server = WebsocketServer(PORT, host="0.0.0.0")
server.set_fn_new_client(new_client)
server.set_fn_client_left(client_left)
server.set_fn_message_received(message_received)
server.run_forever()