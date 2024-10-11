package SplitMate.MQTT;

import SplitMate.domain.*;
import SplitMate.mapper.*;
import SplitMate.service.SensorDataService;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import org.eclipse.paho.client.mqttv3.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

@Component
public class MqttService implements MqttCallback {

    private static final String BROKER_URL = "tcp://192.168.50.227:1883";
    private static final String CLIENT_ID = "java_client";
    private static final String TOPIC_USAGE = "usage/#";
    private static final String TOPIC_BLUETOOTH = "";
    private static final String username = "guanqiao";
    private static final String password = "77136658Rm.";
    private final SensorDataService sensorDataService;
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
            MqttClient client = new MqttClient(BROKER_URL, CLIENT_ID);
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
                new Thread(() -> {
                    AtomicReference<String> bluetoothMac = null;

                    try {
                        // 启动蓝牙 MAC 地址接收的主题
                        client.subscribe(TOPIC_BLUETOOTH, (btTopic, btMessage) -> {
                            bluetoothMac.set(new String(btMessage.getPayload()));
                            System.out.println("Received Bluetooth MAC: " + bluetoothMac);
                        });

                        // 等待 3 秒以接收蓝牙信息
                        Thread.sleep(3000);

                        if (bluetoothMac.get() != null) {
                            // 如果接收到蓝牙信息，检查数据库中是否有对应的用户
                            Bluetooth bluetooth = bluetoothMapper.getBluetoothByMacAddress(bluetoothMac.get());
                            if (bluetooth != null) {
                                // 如果找到蓝牙用户，保存设备使用记录
                                System.out.println("Bluetooth information found. Using Bluetooth info for record.");
                                handleBluetoothMessage(payload, bluetooth);
                            } else {
                                System.out.println("Bluetooth not found in the database. Using MQTT message.");
                            }
                        } else {
                            // 如果没有接收到蓝牙信息，使用接收到的 MQTT 信息
                            System.out.println("No Bluetooth information received. Using MQTT message.");
                            handleMessage(payload);
                        }
                    } catch (InterruptedException | MqttException e) {
                        e.printStackTrace();
                    }
                }).start();
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
}

