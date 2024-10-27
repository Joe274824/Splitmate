package SplitMate.MQTT;

import SplitMate.domain.*;
import SplitMate.mapper.*;
import SplitMate.service.SensorDataService;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import org.eclipse.paho.client.mqttv3.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

@Component
public class MqttService implements MqttCallback {

    private static final String BROKER_URL = "tcp://16.51.50.230:1883";
    private static final String CLIENT_ID = "java";
    private static final String TOPIC_USAGE = "usage/#";
    private static final String username = "guanqiao";
    private static final String password = "77136658Rm.";
    private final SensorDataService sensorDataService;

    private MqttClient client;

    @Autowired
    public MqttService(SensorDataService sensorDataService) {
        this.sensorDataService = sensorDataService;
        connectAndSubscribe();
    }
    @Autowired
    public DeviceStatusMapper deviceStatusMapper;
    @Autowired
    public UserMapper userMapper;
    @Autowired
    public DeviceMapper deviceMapper;
    @Autowired
    public DeviceUsageMapper deviceUsageMapper;
    @Autowired
    public BluetoothMapper bluetoothMapper;

    private void connectAndSubscribe() {
        try {
            client = new MqttClient(BROKER_URL, CLIENT_ID);
            MqttConnectOptions options = new MqttConnectOptions();
            options.setCleanSession(true);
            options.setUserName(username);
            options.setPassword(password.toCharArray());
            client.setCallback(this);
            client.connect(options);
            System.out.println("Successful connected to broker");
            client.subscribe(TOPIC_USAGE, (topic, message) -> {
                String payload = new String(message.getPayload());
                System.out.println("Received message: " + payload);
            });

        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void connectionLost(Throwable cause) {
        System.out.println("Connection lost, trying to reconnect...");
        connectAndSubscribe();  // try reconnection
    }

    @Override
    public void messageArrived(String topic, MqttMessage mqttMessage) throws Exception {
        String payload = new String(mqttMessage.getPayload());
        System.out.println("Received message: " + payload);
        handleMessage(payload);  // process massage
    }

    @Override
    public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {

    }

    private void handleBluetoothMessage(String payload, Bluetooth bluetooth) {
        String username = bluetooth.getUsername();
        JSONObject jsonObject = JSON.parseObject(payload);
        jsonObject.put("user", username);
        payload = JSON.toJSONString(jsonObject);
        handleMessage(payload);
    }

    private String handleMessage(String payload) {
        SensorData sensorData = new SensorData();
        JSONObject jsonObject = JSON.parseObject(payload);
        System.out.println(jsonObject.toJSONString());
        Object time = jsonObject.getTimestamp("time");
        String device = jsonObject.getString("device");
        String username = jsonObject.getString("user");
        String category = jsonObject.getString("category");
        if (username.equals("Unknown")) {
            System.out.println("Unknown detective");
            return "no user detective";
        }
        if (username.equals("guanqiao")) {
            username = "admin";
        }
        DeviceUsage deviceUsage = new DeviceUsage();
        Device device1 = deviceMapper.getDeviceByName(device);
        deviceUsage.setDevice(device1);
        User user = userMapper.findByUsername(username);
        deviceUsage.setUser(user);
        DeviceStatus status = deviceStatusMapper.getDeviceStatusByName(device);
        if (Objects.equals(status.getDeviceStatus(), "0")) {
            System.out.println("device open");
            deviceUsage.setStartTime((Timestamp) time);
            status.setDeviceStatus("1");
            deviceStatusMapper.updateDeviceStatus(status);
            deviceUsageMapper.insertDeviceUsage(deviceUsage);
            System.out.println("save successful！");
        } else {
            System.out.println("device close");
            status.setDeviceStatus("0");
            deviceStatusMapper.updateDeviceStatus(status);
            DeviceUsage deviceUsageByDeviceId = deviceUsageMapper.getDeviceUsageByDeviceId(device1.getId());
            Timestamp startTime = deviceUsageByDeviceId.getStartTime();
            LocalDateTime startTime1 = startTime.toLocalDateTime();
            LocalDateTime endTime = LocalDateTime.now();
            deviceUsageByDeviceId.setEndTime(Timestamp.valueOf(endTime));
            long usageTime = Duration.between(startTime1, endTime).getSeconds() / 60;
            deviceUsageByDeviceId.setUsageTime(Math.toIntExact(usageTime));
            deviceUsageMapper.updateDeviceUsage(deviceUsageByDeviceId);
            System.out.println("save successful！");
        }

        sensorData.setData(payload);
        sensorDataService.saveSensorData(sensorData);
        return "save successful";
    }

    public void sendPhotoOverMqtt(Long deviceId, String name, MultipartFile photo, boolean isUserPhoto) {
        try (InputStream inputStream = photo.getInputStream();
             ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream()) {

            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) != -1) {
                byteArrayOutputStream.write(buffer, 0, length);
            }

            String encodedPhoto = Base64.getEncoder().encodeToString(byteArrayOutputStream.toByteArray());
            String id_name = deviceId + "_" + name;

            JSONObject jsonObject = new JSONObject();
            jsonObject.put("id_name_category", id_name);
            jsonObject.put("photoData", encodedPhoto);

            String topic = isUserPhoto ? "data/face" : "data/device";
            MqttMessage message = new MqttMessage(jsonObject.toJSONString().getBytes());

            client.publish(topic, message); // 发布构造的消息

            System.out.println("照片数据已发送到 MQTT 代理以进行训练。");
        } catch (Exception e) {
            e.printStackTrace(); // 考虑改为日志记录
        }
    }
}

