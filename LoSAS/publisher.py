import paho.mqtt.client as mqtt
import time

broker = "192.168.1.79"  # use your computer’s LAN IP if testing with iPhone
port = 1883
topic = "test/hello"

client = mqtt.Client()
client.connect(broker, port, 60)

while True:
    msg = "Hello from Python!"
    client.publish(topic, msg)
    print(f"Published: {msg}")
    time.sleep(5)

