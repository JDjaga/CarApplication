import asyncio
import websockets
import json

connected_clients = set()

async def handler(websocket, path):
    # Register the client
    connected_clients.add(websocket)
    try:
        async for message in websocket:
            # Broadcast the message to all connected clients
            for client in connected_clients:
                if client != websocket:
                    await client.send(message)
    except websockets.ConnectionClosed:
        pass
    finally:
        connected_clients.remove(websocket)

async def send_update(data):
    # Broadcast updates to all clients
    for client in connected_clients:
        try:
            await client.send(json.dumps(data))
        except Exception as e:
            print(f"Error sending data: {e}")

# Start the server
start_server = websockets.serve(handler, "localhost", 5678)
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()

