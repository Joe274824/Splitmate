import paho.mqtt.client as mqtt

# MQTT 配置
broker_address = "10.210.65.16"
port = 1883
topic = "usage/elec"
username = "guanqiao"
password = "77136658Rm."

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
    else:
        print(f"Failed to connect, return code {rc}")

def on_publish(client, userdata, mid):
    print("Message published!")

def test_mqtt_connection():
    # 创建MQTT客户端并配置连接信息
    client = mqtt.Client()
    client.username_pw_set(username, password)

    # 设置连接和发布回调函数
    client.on_connect = on_connect
    client.on_publish = on_publish

    # 连接MQTT Broker
    client.connect(broker_address, port)

    # 启动客户端的网络循环
    client.loop_start()

    # 发送测试消息
    test_message = "Hello, MQTT!"
    result = client.publish(topic, test_message)
    
    # 等待消息发布完成
    result.wait_for_publish()

    print(f"Test message sent to topic '{topic}': {test_message}")

    # 停止网络循环
    client.loop_stop()

if __name__ == "__main__":
    test_mqtt_connection()
