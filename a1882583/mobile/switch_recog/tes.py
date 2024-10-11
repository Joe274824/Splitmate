import os
import base64
import numpy as np
import cv2
import paho.mqtt.client as mqtt

# MQTT 配置
broker_address = "10.210.65.16"
port = 1883
topic = "video/stream"
username = "guanqiao"
password = "77136658Rm."

# 图像保存目录
output_image_dir = '/home/hgq/Projects/mobile/switch_recog/received_images'
os.makedirs(output_image_dir, exist_ok=True)

def save_received_image(image, output_dir):
    # 根据时间戳生成唯一文件名
    filename = 'received_image.png'
    image_path = os.path.join(output_dir, filename)
    cv2.imwrite(image_path, image)
    print(f"Received image saved as {image_path}")
    return image_path

def on_message(client, userdata, message):
    print("Received a new message from topic:", message.topic)
    
    # 解码接收到的图像数据
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    
    if image is None:
        print("Error: Could not decode the image.")
        return
    
    # 保存接收到的图像
    save_received_image(image, output_image_dir)

def setup_mqtt_client():
    client = mqtt.Client()
    client.username_pw_set(username, password)
    client.connect(broker_address, port=1883)
    return client

def main():
    client = setup_mqtt_client()
    client.on_message = on_message
    client.subscribe(topic)
    print(f"Subscribed to topic {topic} and waiting for messages...")
    client.loop_forever()

if __name__ == "__main__":
    main()
