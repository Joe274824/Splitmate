package SplitMate.MQTT;

import SplitMate.domain.SensorData;
import SplitMate.service.SensorDataService;
import org.eclipse.paho.client.mqttv3.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class MqttService {

    private static final String BROKER_URL = "tcp://10.210.65.16:1883";
    private static final String CLIENT_ID = "java_client";
    private static final String TOPIC = "user/usage";
    private static final String username = "guanqiao";
    private static final String password = "77136658Rm";

    private final SensorDataService sensorDataService;

    @Autowired
    public MqttService(SensorDataService sensorDataService) {
        this.sensorDataService = sensorDataService;
        connectAndSubscribe();
    }

    private void connectAndSubscribe() {
        try {
            MqttClient client = new MqttClient(BROKER_URL, CLIENT_ID);
            MqttConnectOptions options = new MqttConnectOptions();
            options.setCleanSession(true);
            options.setUserName(username);
            options.setPassword(password.toCharArray());
            client.connect(options);
            System.out.println("Successful connected to broker");
            client.subscribe(TOPIC, (topic, message) -> {
                String payload = new String(message.getPayload());
                System.out.println("Received message: " + payload);
                handleMessage(payload);
            });

        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    private void handleMessage(String payload) {
        // 处理消息并保存到数据库
        SensorData sensorData = new SensorData();
        sensorData.setData(payload);
        sensorDataService.saveSensorData(sensorData);
    }
}

