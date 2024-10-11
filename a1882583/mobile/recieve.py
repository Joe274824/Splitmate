import cv2
import paho.mqtt.client as mqtt
import base64
import numpy as np
import ssl

broker_address = "maroonhoney-qtztk1.a02.usw2.aws.hivemq.cloud"
port = 8883
topic = "video/stream"
username = "guanqiao"
password = "77136658Rm."

video_name = "output_video.avi"
fourcc = cv2.VideoWriter_fourcc(*'XVID')
fps = 20.0 
frame_size = (640, 480)  
out = cv2.VideoWriter(video_name, fourcc, fps, frame_size)

def on_message(client, userdata, message):
    jpg_as_text = message.payload.decode('utf-8')
    jpg_original = base64.b64decode(jpg_as_text)
    np_arr = np.frombuffer(jpg_original, dtype=np.uint8)
    img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if img.shape[:2] != frame_size:
        img = cv2.resize(img, frame_size)

    # 写入视频文件
    out.write(img)
    print("Frame written to video")

# 创建 MQTT 客户端
client = mqtt.Client()

# 设置 TLS
client.tls_set(tls_version=ssl.PROTOCOL_TLS)

# 设置用户名和密码
client.username_pw_set(username, password)

# 连接到 HiveMQ Cloud 的 MQTT 代理
client.connect(broker_address, port=port)

# 设置回调函数
client.on_message = on_message

# 订阅视频流主题
client.subscribe(topic)

# 开始接收消息
client.loop_forever()

# 释放视频写入对象
out.release()
print("Video saved successfully")
