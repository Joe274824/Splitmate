import cv2
import paho.mqtt.client as mqtt
import base64
import numpy as np
import ssl
import os
import json
import mediapipe as mp
from datetime import datetime
import math

broker_address = "192.168.50.227"
port = 1883
topic = "usage/elec"
username = "guanqiao"
password = "77136658Rm."

names = {1: 'guanqiao'}
recognizer = cv2.face.LBPHFaceRecognizer_create()
recognizer.read('/home/hgq/Projects/mobile/trainer.yml')

face_detector = cv2.CascadeClassifier("/home/hgq/Projects/mobile/haarcascade_frontalface_default.xml")
save_dir = "/home/hgq/Projects/mobile/received_images"
os.makedirs(save_dir, exist_ok=True)

json_path = '/home/hgq/Projects/mobile/switch_recog/switch_position.json'
with open(json_path, 'r') as json_file:
    switch_data = json.load(json_file)

switch_id = switch_data["switch_id"]
switch_name = switch_data["switch_name"]
position = switch_data["position"]
category = switch_data["category"]
switch_x1, switch_y1 = position["x1"], position["y1"]
switch_x2, switch_y2 = position["x2"], position["y2"]

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils

def face_detect_and_recognize(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_detector.detectMultiScale(gray)
    recognized_faces = []

    for x, y, w, h in faces:
        id, confidence = recognizer.predict(gray[y:y + h, x:x + w])
        if confidence < 65:
            name = names.get(id, "Unknown")
        else:
            name = "Unknown"
        recognized_faces.append((name, (x, y, w, h)))
        print('Label:', id, 'Name:', name, 'Confidence:', confidence)

        cv2.rectangle(img, (x, y), (x + w, y + h), (255, 0, 0), 2)
        cv2.putText(img, f'{name}', (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 0, 0), 2)

    return recognized_faces

def hand_detect_and_switch_check(img):
    image_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    hands_positions = []
    switch_touched = False

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            finger_tips_ids = [4, 8, 12, 16, 20]
            hand_position = []

            for tip_id in finger_tips_ids:
                x = int(hand_landmarks.landmark[tip_id].x * img.shape[1])
                y = int(hand_landmarks.landmark[tip_id].y * img.shape[0])
                hand_position.append((x, y))

                if switch_x1 < x < switch_x2 and switch_y1 < y < switch_y2:
                    switch_touched = True
            hands_positions.append(hand_position)

    return switch_touched, hands_positions

def calculate_distance(x1, y1, x2, y2):
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)

def associate_hand_to_nearest_face(hands_positions, recognized_faces):
    min_distance = float('inf')
    closest_name = "Unknown"

    for hand_pos in hands_positions:
        hx, hy = hand_pos[0]

        for name, (fx, fy, fw, fh) in recognized_faces:
            face_center_x = fx + fw / 2
            face_center_y = fy + fh / 2
            distance = calculate_distance(hx, hy, face_center_x, face_center_y)
            if distance < min_distance:
                min_distance = distance
                closest_name = name

    return closest_name

def on_message(client, userdata, message):
    print("Received a new message from topic:", message.topic)
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    recognized_faces = face_detect_and_recognize(img)
    switch_touched, hands_positions = hand_detect_and_switch_check(img)

    cv2.rectangle(img, (switch_x1, switch_y1), (switch_x2, switch_y2), (0, 255, 0), 2)
    cv2.putText(img, f'Switch: {switch_name}', (switch_x1, switch_y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

    if switch_touched:
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        responsible_name = associate_hand_to_nearest_face(hands_positions, recognized_faces)
        print(f"Switch Touched by {responsible_name} at {current_time}")
        cv2.putText(img, f"Switch Touched by {responsible_name}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    cv2.imshow('Video Stream', img)
    cv2.waitKey(1)

client = mqtt.Client()
# client.tls_set(tls_version=ssl.PROTOCOL_TLS)
client.username_pw_set(username, password)
client.connect(broker_address, port=1883)
client.on_message = on_message
client.subscribe(topic)
client.loop_forever()
