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

broker_address = "10.210.65.16"
port = 1883
topic = "video/stream"
username = "guanqiao"
password = "77136658Rm."

# 人脸识别部分
names = {1: 'guanqiao'}
recognizer = cv2.face.LBPHFaceRecognizer_create()
recognizer.read('/home/hgq/Projects/mobile/trainer.yml')

face_detector = cv2.CascadeClassifier("/home/hgq/Projects/mobile/haarcascade_frontalface_default.xml")

# 开关模板目录
template_dir = '/home/hgq/Projects/mobile/switch_recog/switches'
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils

# 用于存储第一次识别到的开关位置
first_frame_switch_data = None

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
        #cv2.rectangle(img, (x, y), (x + w, y + h), (255, 0, 0), 2)
       # cv2.putText(img, f'{name}', (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 0, 0), 2)
    
    return recognized_faces

def hand_detect_and_switch_check(img, switch_data):
    image_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    hands_positions = []

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            finger_tips_ids = [4, 8, 12, 16, 20]  # Thumb tip, index tip, etc.
            for tip_id in finger_tips_ids:
                x = int(hand_landmarks.landmark[tip_id].x * img.shape[1])
                y = int(hand_landmarks.landmark[tip_id].y * img.shape[0])
                
                for switch in switch_data:
                    switch_x1, switch_y1 = switch['position']['x1'], switch['position']['y1']
                    switch_x2, switch_y2 = switch['position']['x2'], switch['position']['y2']
                    
                    # 判断手指是否进入开关区域
                    if switch_x1 <= x <= switch_x2 and switch_y1 <= y <= switch_y2:
                        return True, (x, y)  # 返回True表示触碰到了开关
    
    return False, None

def calculate_distance(x1, y1, x2, y2):
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)

def associate_hand_to_nearest_face(hand_pos, recognized_faces):
    min_distance = float('inf')
    closest_name = "Unknown"

    hx, hy = hand_pos

    for name, (fx, fy, fw, fh) in recognized_faces:
        face_center_x = fx + fw / 2
        face_center_y = fy + fh / 2
        distance = calculate_distance(hx, hy, face_center_x, face_center_y)
        if distance < min_distance:
            min_distance = distance
            closest_name = name

    return closest_name

# Perform switch recognition on the first frame only
def switch_recognition(image):
    all_switch_data = []

    for filename in os.listdir(template_dir):
        if filename.endswith('.png'):
            switch_id, switch_name, category, weight_with_ext = filename.split('_')
            weight = os.path.splitext(weight_with_ext)[0]
            template = cv2.imread(os.path.join(template_dir, filename), cv2.IMREAD_COLOR)
            template_height, template_width = template.shape[:2]
            result = cv2.matchTemplate(image, template, cv2.TM_CCOEFF_NORMED)
            min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

            switch_x1, switch_y1 = max_loc
            switch_x2, switch_y2 = switch_x1 + template_width, switch_y1 + template_height

           # cv2.rectangle(image, (switch_x1, switch_y1), (switch_x2, switch_y2), (0, 255, 0), 2)

            switch_data = {
                "switch_id": switch_id,
                "switch_name": switch_name,
                "category": category,
                "weight": weight,
                "position": {
                    "x1": switch_x1,
                    "y1": switch_y1,
                    "x2": switch_x2,
                    "y2": switch_y2
                }
            }
            all_switch_data.append(switch_data)

    return all_switch_data

def on_message(client, userdata, message):
    global first_frame_switch_data

    print("Received a new message from topic:", message.topic)
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    # Perform face recognition
    recognized_faces = face_detect_and_recognize(img)
    
    # If this is the first frame, perform switch recognition and store the results
    if first_frame_switch_data is None:
        first_frame_switch_data = switch_recognition(img)
        print("Switches recognized in the first frame")

    # Use the stored switch data for subsequent frames
    switch_touched, touch_position = hand_detect_and_switch_check(img, first_frame_switch_data)

    # Draw switches on the frame
    for switch in first_frame_switch_data:
        switch_name = switch["switch_name"]
        position = switch["position"]
        switch_x1, switch_y1 = position["x1"], position["y1"]
        switch_x2, switch_y2 = position["x2"], position["y2"]
       # cv2.rectangle(img, (switch_x1, switch_y1), (switch_x2, switch_y2), (0, 255, 0), 2)
        #cv2.putText(img, f'Switch: {switch_name}', (switch_x1, switch_y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

    if switch_touched:
        responsible_name = associate_hand_to_nearest_face(touch_position, recognized_faces)
        print(f"Switch touched by {responsible_name}")
        #cv2.putText(img, f"Switch touched by {responsible_name}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    cv2.imshow('Video Stream', img)
    cv2.waitKey(1)

client = mqtt.Client()
client.username_pw_set(username, password)
client.connect(broker_address, port=1883)
client.on_message = on_message
client.subscribe(topic)
client.loop_forever()
