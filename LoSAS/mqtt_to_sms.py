import paho.mqtt.client as mqtt
from twilio.rest import Client

# Twilio credentials (from Twilio Console)
TWILIO_ACCOUNT_SID = ""
TWILIO_AUTH_TOKEN = ""
TWILIO_PHONE = ""     # your Twilio number
TARGET_PHONE = ""    # your phone number

# Set up Twilio client
twilio_client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# MQTT settings
MQTT_BROKER = "192.168.1.79"  # or your broker's IP
MQTT_PORT = 1883
MQTT_TOPIC = "test/hello"

def on_message(client, userdata, message):
    msg = message.payload.decode()
    print(f"📩 Received: {msg}")

    # Send SMS
    sms = twilio_client.messages.create(
        body=f"MQTT message: {msg}",
        from_=TWILIO_PHONE,
        to=TARGET_PHONE
    )
    print(f"📤 SMS sent with SID: {sms.sid}")

def main():
    client = mqtt.Client()
    client.on_message = on_message
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.subscribe(MQTT_TOPIC)
    print(f"🔌 Subscribed to {MQTT_TOPIC}, waiting for messages...")
    client.loop_forever()

if __name__ == "__main__":
    main()
