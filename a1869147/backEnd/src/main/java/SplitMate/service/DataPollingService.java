package SplitMate.service;

import SplitMate.controller.WebSocketServer;
import SplitMate.domain.DeviceUsage;
import com.alibaba.fastjson.JSON;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
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
    public void pollDatabase() throws IOException {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        String formattedDate = sdf.format(lastTimestamp);
        List<DeviceUsage> updatedData = deviceUsageService.getUpdatedDataSince(formattedDate);

        // 更新 lastTimestamp
        lastTimestamp = System.currentTimeMillis();
        if (!updatedData.isEmpty()) {
            String notificationMessage = "have new massage";
            webSocketServer.sendInfo(notificationMessage, updatedData.get(0).getUser().getId());
            }
    }
}
