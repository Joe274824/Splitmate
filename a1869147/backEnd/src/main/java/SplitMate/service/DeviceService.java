package SplitMate.service;

import SplitMate.domain.Device;
import SplitMate.domain.DeviceStatus;
import SplitMate.mapper.DeviceMapper;
import SplitMate.mapper.DeviceStatusMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.util.List;

import static org.springframework.http.MediaTypeFactory.getMediaType;

@Service
public class DeviceService {

    @Autowired
    private DeviceMapper deviceMapper;

    @Autowired
    private DeviceStatusMapper deviceStatusMapper;

    @Autowired
    private MinioService minioService;

    private static final String BUCKET_NAME = "device-images";

    public List<Device> getAllDevices() {
        return deviceMapper.getAllDevices();
    }

    public Device getDeviceById(Long id) {
        return deviceMapper.getDeviceById(id);
    }

    public String createDevice(Device device) {
        Device byName = deviceMapper.getDeviceByName(device.getName());
        if (byName != null) {
            return "name has been used";
        }
        deviceMapper.insertDevice(device);
        Device deviceByName = deviceMapper.getDeviceByName(device.getName());
        DeviceStatus deviceStatus = new DeviceStatus();
        deviceStatus.setDeviceStatus("0");
        deviceStatus.setDeviceName(device.getName());
        deviceStatus.setDeviceId(deviceByName.getId());
        deviceStatusMapper.insertDeviceStatus(deviceStatus);
        return "device add successfully";
    }

    public void updateDevice(Device device) {
        deviceMapper.updateDevice(device);
    }

    public void deleteDevice(Long id) {
        deviceMapper.deleteDevice(id);
    }

    public void saveDevicePhoto(Long deviceId, MultipartFile photo) throws IOException {
        String fileName = "device_" + deviceId + (photo.getOriginalFilename());
        try (InputStream inputStream = photo.getInputStream()) {
            minioService.uploadFile(BUCKET_NAME, fileName, inputStream, photo.getContentType(), photo.getSize());
        } catch (Exception e) {
            throw new IOException("File upload failed: " + e.getMessage(), e);
        }

        Device device = new Device();
        device.setId(deviceId);
        device.setImagePath("minio_bucket:" + BUCKET_NAME + "/" + fileName); // 更新为MinIO的URL
        deviceMapper.updateDevice(device);
    }

    public ResponseEntity<Resource> getDevicePhoto(Long deviceId) {
        Device device = getDeviceById(deviceId);
        if (device == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }

        String objectName = device.getImagePath().substring(device.getImagePath().indexOf("/") + 1);
        MediaType mediaType = minioService.getMediaType(objectName);
        try {
            InputStream inputStream = minioService.downloadFile(BUCKET_NAME, objectName);
            Resource resource = new InputStreamResource(inputStream);
            return ResponseEntity.ok()
                    .contentType(mediaType) // 可以根据实际的内容类型进行调整
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    // 根据文件名获取扩展名
    public String getFileExtension(String originalFilename) {
        return originalFilename.substring(originalFilename.lastIndexOf("."));
    }

}
