import paho.mqtt.client as mqtt

# MQTT broker 配置
broker_address = "10.13.92.37"  # 如果在本地运行，使用 localhost
port = 1883
topic = "usage/elec"
username = "guanqiao"  # 如果设置了用户名，替换为实际值
password = "77136658Rm."  # 如果设置了密码，替换为实际值

# 创建 MQTT 客户端对象
client = mqtt.Client()

# 设置用户名和密码（如果需要）
client.username_pw_set(username, password)

# 连接到 MQTT broker
client.connect(broker_address, port)

# 发送消息
message = "hello world"
client.publish(topic, message)

# 断开连接
client.disconnect()

print(f"已发送消息 '{message}' 到主题 '{topic}'")
