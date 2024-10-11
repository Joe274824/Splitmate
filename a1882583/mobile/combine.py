import cv2
import json
import os
import base64
import numpy as np
import paho.mqtt.client as mqtt
from datetime import datetime
import math
import mediapipe as mp

broker_address = "10.210.65.16"
port = 1883
topic = "video/stream"
user_name = "guanqiao"
password = "77136658Rm."

template_dir = '/home/hgq/Projects/mobile/switch_recog/switches'

recognizer = cv2.face.LBPHFaceRecognizer_create()
recognizer.read('/home/hgq/Projects/mobile/trainer.yml')
face_detector = cv2.CascadeClassifier("/home/hgq/Projects/mobile/haarcascade_frontalface_default.xml")
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils

json_path = '/home/hgq/Projects/mobile/switch_recog/switch_positions.json'
with open(json_path, 'r') as json_file:
    all_switch_data = json.load(json_file)

def face_detect_and_recognize(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_detector.detectMultiScale(gray)
    recognized_faces = []
    for x, y, w, h in faces:
        id, confidence = recognizer.predict(gray[y:y + h, x:x + w])
        name = names.get(id, "Unknown") if confidence < 65 else "Unknown"
        recognized_faces.append((name, (x, y, w, h)))
    return recognized_faces

def hand_detect_and_switch_check(img, all_switch_data):
    image_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    hands_positions = []
    touched_switches = []
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            finger_tips_ids = [4, 8, 12, 16, 20]
            hand_position = []
            for tip_id in finger_tips_ids:
                x = int(hand_landmarks.landmark[tip_id].x * img.shape[1])
                y = int(hand_landmarks.landmark[tip_id].y * img.shape[0])
                hand_position.append((x, y))
                for switch_data in all_switch_data:
                    position = switch_data["position"]
                    switch_x1, switch_y1 = position["x1"], position["y1"]
                    switch_x2, switch_y2 = position["x2"], position["y2"]
                    if switch_x1 < x < switch_x2 and switch_y1 < y < switch_y2:
                        touched_switches.append({
                            "switch_name": switch_data["switch_name"],
                            "category": switch_data["category"],
                            "hand_position": (x, y)
                        })
            hands_positions.append(hand_position)
    return touched_switches, hands_positions

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
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    recognized_faces = face_detect_and_recognize(img)
    touched_switches, hands_positions = hand_detect_and_switch_check(img, all_switch_data)
    if touched_switches:
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        for switch in touched_switches:
            switch_name = switch["switch_name"]
            category = switch["category"]
            hand_position = switch["hand_position"]
            responsible_name = #associate_hand_to_nearest_face([hand_position], recognized_faces)
            if category.lower() == "elec":
                usage_topic = "usage/elec"
                
            elif category.lower() == "water":
                usage_topic = "usage/water"
            else:
                usage_topic = "usage/unknown"
            print(f"Time: {current_time}, Switch: {switch_name}, Category: {category}, Touched by: {responsible_name}")
            message_payload = {
                "time": current_time,
                "switch": device,
                "responsible": username,
                "category": category
            }
            message_json = json.dumps(message_payload)
            client.publish(usage_topic, message_json)

def on_message(client, userdata, message):
    usage_topic = 'usage/elec'
    current_time = '2024-01-01 13:13:00'
    device = 'main_light'
    username = 'guanqiao' 
    category = 'elec'
    
    message_payload = {
        "time": current_time,
        "switch": device,
        "responsible": username, 
        "category": category
    }
    print("load")
    message_json = json.dumps(message_payload)
    client.publish(usage_topic, message_json)


client = mqtt.Client()
client.username_pw_set(user_name, password)
client.connect(broker_address, port=1883)
client.on_message = on_message
client.subscribe(topic)
client.loop_forever()
