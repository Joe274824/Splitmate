package SplitMate.service;

import SplitMate.controller.WebSocketServer;
import SplitMate.domain.DeviceUsage;
import com.alibaba.fastjson.JSON;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

@Service
public class DataPollingService {

    @Autowired
    private DeviceUsageService deviceUsageService;

    @Autowired
    private WebSocketServer webSocketServer;

    private Long lastTimestamp = 0L; // 用于存储上次查询的时间戳

    // 定期查询数据库
    @Scheduled(fixedRate = 5000) // 每5秒执行一次
    public void pollDatabase() {
        List<DeviceUsage> updatedData = deviceUsageService.getUpdatedDataSince(lastTimestamp);

        // 更新 lastTimestamp
        lastTimestamp = System.currentTimeMillis();

        for (DeviceUsage data : updatedData) {
            // 推送到 WebSocket 客户端
            String message = JSON.toJSONString(data);
            try {
                webSocketServer.sendInfo(message, data.getUser().getId());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
