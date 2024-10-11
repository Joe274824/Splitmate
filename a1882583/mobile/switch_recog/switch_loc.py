import cv2
import json
import os
import base64
import numpy as np
import paho.mqtt.client as mqtt

broker_address = "10.210.65.16"
port = 1883
topic = "video/stream"
username = "guanqiao"
password = "77136658Rm."

template_dir = '/home/hgq/Projects/mobile/switch_recog/switches'

def on_message(client, userdata, message):
    print("Received a new message from topic:", message.topic)
    
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    
    if image is None:
        print("Error: Could not decode the image.")
        return
    
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
                }
            }
            all_switch_data.append(switch_data)
    output_path = os.path.join(template_dir, 'detected_switches.png')
    cv2.imwrite(output_path, image)
    json_path = os.path.join(template_dir, 'switch_positions.json')
    with open(json_path, 'w') as json_file:
        json.dump(all_switch_data, json_file)

    print(f"Processed image saved as {output_path}")
    print(f"Switch positions and details saved as {json_path}")
    client.disconnect()
client = mqtt.Client()
client.username_pw_set(username, password)
client.connect(broker_address, port=1883)
client.on_message = on_message
client.subscribe(topic)
client.loop_start()
client.loop_forever()
