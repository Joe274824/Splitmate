import cv2
import paho.mqtt.client as mqtt
import base64
import numpy as np
import ssl
import os
from datetime import datetime

broker_address = "maroonhoney-qtztk1.a02.usw2.aws.hivemq.cloud"
port = 8883
topic = "video/stream"
username = "guanqiao"
password = "77136658Rm."

names = {1: 'guanqiao',2:'xuanqiao'}
recognizer = cv2.face.LBPHFaceRecognizer_create()
recognizer.read('/home/hgq/Projects/mobile/trainer.yml')

face_detector = cv2.CascadeClassifier("/home/hgq/Projects/mobile/haarcascade_frontalface_default.xml")
save_dir = "/home/hgq/Projects/mobile/received_images"
os.makedirs(save_dir, exist_ok=True)
def face_detect_and_recognize(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_detector.detectMultiScale(gray)
    for x, y, w, h in faces:
        id, confidence = recognizer.predict(gray[y:y + h, x:x + w])
        if confidence < 65:
            name = names.get(id, "Unknown")
        else:
            id = "Unknown"
            name = "Unknown"
        print('label:', id, 'confidence:', confidence)

def on_message(client, userdata, message):
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    face_detect_and_recognize(img)
    # timestamp = datetime.now().strftime("%Y%m%d_%H%M%S%f")
    # file_name = os.path.join(save_dir, f"received_image_{timestamp}.jpg")
    # cv2.imwrite(file_name, img)
    # print(f"Image saved as {file_name}")
client = mqtt.Client()
client.tls_set(tls_version=ssl.PROTOCOL_TLS)
client.username_pw_set(username, password)
client.connect(broker_address, port=port)
client.on_message = on_message
client.subscribe(topic)
client.loop_forever()
