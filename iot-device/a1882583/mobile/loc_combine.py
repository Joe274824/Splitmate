import os
import cv2
import torch
import numpy as np
from facenet_pytorch import InceptionResnetV1, MTCNN
from PIL import Image
import paho.mqtt.client as mqtt
import base64
import json
import mediapipe as mp
import math
from datetime import datetime

broker_address = "0.0.0.0"
port = 1883
topic = "video/stream"
username = "guanqiao"
password = "77136658Rm."

aws_broker_address = "16.51.50.230"
aws_port = 1883
aws_username = "guanqiao"
aws_password = "77136658Rm."

# FaceNet and MTCNN initialization
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
mtcnn = MTCNN(keep_all=True, device=device)  
facenet = InceptionResnetV1(pretrained='vggface2').eval().to(device) 
faces_dir = '/home/hgq/Projects/mobile/face_data/'
names = {}
face_encodings = [] 

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=2, min_detection_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils

def load_faces_from_dir():
    current_id = 0
    for person_name in os.listdir(faces_dir):
        person_dir = os.path.join(faces_dir, person_name)
        if os.path.isdir(person_dir):
            names[current_id] = person_name
            for image_file in os.listdir(person_dir):
                image_path = os.path.join(person_dir, image_file)
                img = Image.open(image_path)
                
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                
                faces, probs = mtcnn(img, return_prob=True) 
                if faces is not None:
                    for face, prob in zip(faces, probs):
                        if prob > 0.90:
                            face_embedding = facenet(face.unsqueeze(0).to(device))
                            face_encodings.append((current_id, face_embedding))
            current_id += 1
    print(f"Loaded faces for {len(names)} individuals.")
def face_detect_and_recognize(img):
    img_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    faces, probs = mtcnn(img_pil, return_prob=True)
    recognized_faces = []

    if faces is not None:
        for i, face in enumerate(faces):
            if probs[i] > 0.90: 
                face_embedding = facenet(face.unsqueeze(0).to(device))

                min_distance = float('inf')
                best_match = "Unknown"
                for id, known_embedding in face_encodings:
                    dist = torch.norm(face_embedding - known_embedding)
                    if dist < min_distance:
                        min_distance = dist
                        best_match = names.get(id, "Unknown")

                if min_distance > 0.9:
                    best_match = "Unknown"

                x1, y1, x2, y2 = map(int, mtcnn.detect(img_pil)[0][i])
                recognized_faces.append((best_match, (x1, y1, x2, y2)))

                cv2.rectangle(img, (x1, y1), (x2, y2), (255, 0, 0), 2)
                cv2.putText(img, f'{best_match}', (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 0, 0), 2)
                print(f"Recognized {best_match} with distance {min_distance:.2f}")

    return recognized_faces

template_dir = '/home/hgq/Projects/mobile/switch_recog/switches'
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

            cv2.rectangle(image, (switch_x1, switch_y1), (switch_x2, switch_y2), (0, 255, 0), 2)

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
                },
                "published": False 
            }
            all_switch_data.append(switch_data)

    return all_switch_data

def hand_detect_and_switch_check(img, switch_data):
    image_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    hands_positions = []

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            for i, landmark in enumerate(hand_landmarks.landmark):
                x = int(landmark.x * img.shape[1])
                y = int(landmark.y * img.shape[0])
                print(f"Landmark {i}: (x: {x}, y: {y})")
            
            mp_drawing.draw_landmarks(img, hand_landmarks, mp_hands.HAND_CONNECTIONS)

            finger_tips_ids = [4, 8, 12, 16, 20]
            for tip_id in finger_tips_ids:
                x = int(hand_landmarks.landmark[tip_id].x * img.shape[1])
                y = int(hand_landmarks.landmark[tip_id].y * img.shape[0])
                
                for switch in switch_data:
                    switch_x1, switch_y1 = switch['position']['x1'], switch['position']['y1']
                    switch_x2, switch_y2 = switch['position']['x2'], switch['position']['y2']
                    if switch_x1 <= x <= switch_x2 and switch_y1 <= y <= switch_y2:
                        return True, (x, y)
    
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

last_frame_sequence = -1
first_frame_switch_data = None
import json
import base64
import cv2
import numpy as np
from datetime import datetime

last_frame_sequence = -1
first_frame_switch_data = None 

def on_message(client, userdata, message):
    global last_frame_sequence, first_frame_switch_data
    print("Received a new message from topic:", message.topic)

    message_json = json.loads(message.payload.decode('utf-8'))
    frames_data = message_json.get("frames", [])
    sequence_number = message_json.get("sequence", -1) 
    if sequence_number > last_frame_sequence or sequence_number == -1:
        last_frame_sequence = sequence_number if sequence_number != -1 else last_frame_sequence  

        frames = []
        for frame_data in frames_data:
            jpg_original = base64.b64decode(frame_data)
            np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
            img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
            frames.append(img)

        for i, img in enumerate(frames):
            print(f"Processing frame {i+1}")
            recognized_faces = face_detect_and_recognize(img)

            if first_frame_switch_data is None:
                first_frame_switch_data = switch_recognition(img) 
                print("Switches recognized in the first frame")

            switch_touched, touch_position = hand_detect_and_switch_check(img, first_frame_switch_data)

            for switch in first_frame_switch_data:
                switch_name = switch["switch_name"]
                position = switch["position"]
                switch_x1, switch_y1 = position["x1"], position["y1"]
                switch_x2, switch_y2 = position["x2"], position["y2"]
                cv2.rectangle(img, (switch_x1, switch_y1), (switch_x2, switch_y2), (0, 255, 0), 2)
                cv2.putText(img, f'Switch: {switch_name}', (switch_x1, switch_y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

            if switch_touched:
                responsible_name = associate_hand_to_nearest_face(touch_position, recognized_faces)
                print(f"Switch touched by {responsible_name}")
                cv2.putText(img, f"Switch touched by {responsible_name}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                for switch in first_frame_switch_data:
                    switch_x1, switch_y1 = switch["position"]["x1"], switch["position"]["y1"]
                    switch_x2, switch_y2 = switch["position"]["x2"], switch["position"]["y2"]

                    if switch_x1 <= touch_position[0] <= switch_x2 and switch_y1 <= touch_position[1] <= switch_y2:
                        if not switch["published"]:
                            category = switch["category"]
                            if category == "elec":
                                usage_topic = "usage/elec"
                            elif category == "water":
                                usage_topic = "usage/water"
                            else:
                                usage_topic = "usage/unknown"

                            message_payload = {
                                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                                "device": switch["switch_name"],
                                "user": responsible_name,
                                "category": category
                            }
                            message_json = json.dumps(message_payload)
                            aws_client.publish(usage_topic, message_json)
                            print(f"Published to {usage_topic}: {message_json}")

                            switch["published"] = True
            else:
                for switch in first_frame_switch_data:
                    switch["published"] = False
            cv2.imshow(f'Video Stream Frame', img)
            cv2.waitKey(1)
    else:
        print(f"Frame {sequence_number} is outdated, skipping.")

load_faces_from_dir()

client = mqtt.Client()
client.username_pw_set(username, password)
client.connect(broker_address, port=1883)
client.on_message = on_message
client.subscribe(topic)

aws_client = mqtt.Client()
aws_client.username_pw_set(aws_username, aws_password)
aws_client.connect(aws_broker_address, port=aws_port)

aws_client.loop_start()

client.loop_forever()


