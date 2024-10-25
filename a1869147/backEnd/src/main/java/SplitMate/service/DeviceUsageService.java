package SplitMate.service;

import SplitMate.domain.*;
import SplitMate.mapper.DeviceMapper;
import SplitMate.mapper.DeviceStatusMapper;
import SplitMate.mapper.DeviceUsageMapper;
import SplitMate.mapper.UserMapper;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
public class DeviceUsageService {

    @Autowired
    private DeviceUsageMapper deviceUsageMapper;

    @Autowired
    private DeviceMapper deviceMapper;

    @Autowired
    private UserMapper userMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();
    @Autowired
    private MinioService minioService;
    @Autowired
    private DeviceStatusMapper deviceStatusMapper;

    public List<DeviceUsage> getAllDeviceUsages() {
        return deviceUsageMapper.getAllDeviceUsages();
    }

    public DeviceUsage getDeviceUsageById(Long id) {
        return deviceUsageMapper.getDeviceUsageById(id);
    }

    public void createDeviceUsage(DeviceUsage deviceUsage) {
        deviceUsageMapper.insertDeviceUsage(deviceUsage);
    }

    public void updateDeviceUsage(DeviceUsage deviceUsage) {
        deviceUsageMapper.updateDeviceUsage(deviceUsage);
    }

    public void deleteDeviceUsage(Long id) {
        deviceUsageMapper.deleteDeviceUsage(id);
    }

    public List<DeviceUsage> getDeviceUsageByUsername(String username) {
        return deviceUsageMapper.getDeviceUsageByUsername(username);
    }

    public List<DeviceUsage> getUpdatedDataSince(String timestamp) {
        return deviceUsageMapper.findUpdatedDataSince(timestamp);
    }

    public List<DeviceUsage> getDeviceUsageByMonth(Long userId, LocalDate startOfMonth, LocalDate endOfMonth) {
        return deviceUsageMapper.getDeviceUsageByMonth(userId, startOfMonth, endOfMonth);
    }

    public void processFile(MultipartFile file) throws IOException {

        // 使用BufferedReader按行读取文件
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(file.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println("Processing line: " + line);
                String result = extractAndProcessFields(line);
                System.out.println("Result: " + result);
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        String bucketName = "offline-usages";
        String fileName = "offLine-" + UUID.randomUUID() + "-" + file.getOriginalFilename();
        try(InputStream inputStream = file.getInputStream()) {
            minioService.uploadFile(bucketName, fileName, inputStream, "text/plain", file.getSize());
            System.out.println("File uploaded successfully to MinIO: " + fileName);
        } catch (Exception e) {
            throw new IOException("File upload failed: " + e.getMessage(), e);
        }
    }

    private String extractAndProcessFields(String json) throws Exception {
        JsonNode jsonNode = objectMapper.readTree(json);

        // 提取字段
        String userPhoneId = jsonNode.get("deviceUUID").asText();
        String bleAddress = jsonNode.get("bleUUID").asText();
        String time = jsonNode.get("timestamp").asText();

        Device device = deviceMapper.getDeviceByBLEAddress(bleAddress);
        User user = userMapper.findByPhone(userPhoneId);
        String message = String.format("{\"time\": \"%s\", \"device\": \"%s\", \"user\": \"%s\", \"category\": \"%s\"}",
                time, device.getName(), user.getUsername(), device.getCategory());
        // 保存使用记录
        return handle(message);
    }


    private String handle(String payload) {
        JSONObject jsonObject = JSON.parseObject(payload);
        System.out.println(jsonObject.toJSONString());
        String timeStr = jsonObject.getString("time");
        Timestamp time = null;
        if (timeStr != null) {
            try {
                SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                Date parsedDate = dateFormat.parse(timeStr);
                time = new Timestamp(parsedDate.getTime());
            } catch (ParseException e) {
                e.printStackTrace();
                return "invalid time format";
            }
        } else {
            return "time field is missing";
        }
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
            deviceUsage.setStartTime(time);
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
        return "save successful";
    }
}