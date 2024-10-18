package SplitMate.service;

import SplitMate.domain.Device;
import SplitMate.domain.DeviceStatus;
import SplitMate.mapper.DeviceMapper;
import SplitMate.mapper.DeviceStatusMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.List;

@Service
public class DeviceService {

    @Autowired
    private DeviceMapper deviceMapper;

    @Autowired
    private DeviceStatusMapper deviceStatusMapper;

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
        // 获取临时目录并构造绝对路径
        String tempDir = System.getProperty("java.io.tmpdir");
        String directoryPath = tempDir + "user-photos/" + deviceId;
        File directory = new File(directoryPath);

        if (!directory.exists()) {
            boolean dirCreated = directory.mkdirs(); // 使用mkdirs()确保创建多级目录
            if (!dirCreated) {
                throw new IOException("Failed to create directory: " + directoryPath);
            }
        }

        String fileName = "device_photo" + getFileExtension(photo.getOriginalFilename());
        File destinationFile = new File(directory, fileName);

        // 记录调试信息
        System.out.println("Attempting to save file to: " + destinationFile.getAbsolutePath());
        System.out.println("Uploaded file size: " + photo.getSize() + " bytes");

        try {
            photo.transferTo(destinationFile);
        } catch (IllegalStateException e) {
            throw new IOException("File transfer failed: " + e.getMessage(), e);
        } catch (IOException e) {
            throw new IOException("I/O error occurred while saving file: " + e.getMessage(), e);
        }
        Device device = new Device();
        device.setId(deviceId);
        device.setImagePath(directoryPath + "/" + fileName);
        deviceMapper.updateDevice(device);
    }

    public ResponseEntity<Resource> getDevicePhoto(Long deviceId) {
        Device device = getDeviceById(deviceId);
        if (device == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
        File photoFile = new File(device.getImagePath());

        // 检查文件是否存在
        if (!photoFile.exists()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }

        try {
            // 将文件作为资源返回
            Resource resource = new UrlResource(photoFile.toURI());
            if (resource.exists() || resource.isReadable()) {
                return ResponseEntity.ok()
                        .contentType(MediaType.IMAGE_JPEG)
                        .body(resource);
            } else {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
            }
        } catch (MalformedURLException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    // 根据文件名获取扩展名
    public String getFileExtension(String originalFilename) {
        return originalFilename.substring(originalFilename.lastIndexOf("."));
    }

}
