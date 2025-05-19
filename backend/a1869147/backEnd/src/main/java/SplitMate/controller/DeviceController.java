package SplitMate.controller;

import SplitMate.domain.Device;
import SplitMate.service.DeviceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.net.MalformedURLException;
import java.util.List;

import static com.google.common.io.Files.getFileExtension;

@RestController
@RequestMapping("/devices")
public class DeviceController {

    @Autowired
    private DeviceService deviceService;

    @GetMapping("/house")
    public List<Device> getAllDevices() {
        return deviceService.getAllDevices();
    }

    @GetMapping("/{id}")
    public Device getDeviceById(@PathVariable Long id) {
        return deviceService.getDeviceById(id);
    }

    @PostMapping
    public ResponseEntity<String> createDevice(@RequestBody Device device) {
        String result = deviceService.createDevice(device);
        if (result.equals("name has been used")) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(result);
        } else {
            return ResponseEntity.ok(result);
        }
    }

    @PostMapping(value = "/uploadDevicePhoto", consumes = "multipart/form-data")
    public ResponseEntity<String> uploadDevicePhoto(@RequestParam("deviceId") Long deviceId,
                                                    @RequestParam("photo") MultipartFile photo) {
        // 检查设备是否存在
        Device device = deviceService.getDeviceById(deviceId);
        if (device == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Device not found");
        }

        // 检查文件是否为空
        if (photo.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("The photo file is empty");
        }

        // 处理文件上传
        try {
            // 打印照片原始文件名（用于调试）
            System.out.println("Photo Original Filename: " + photo.getOriginalFilename());

            // 保存照片
            deviceService.saveDevicePhoto(deviceId, photo);

            return ResponseEntity.status(HttpStatus.CREATED).body("Device photo uploaded successfully");

        } catch (Exception e) {
            // 捕获所有异常
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to upload device photo: " + e.getMessage());
        }
    }


    @GetMapping(value = "/{deviceId}/photo", produces = MediaType.IMAGE_JPEG_VALUE)
    public ResponseEntity<Resource> getDevicePhoto(@PathVariable Long deviceId) {
        return deviceService.getDevicePhoto(deviceId);
    }


    @PutMapping("/{id}")
    public void updateDevice(@PathVariable Long id, @RequestBody Device device) {
        device.setId(id);
        deviceService.updateDevice(device);
    }

    @DeleteMapping("/{id}")
    public void deleteDevice(@PathVariable Long id) {
        deviceService.deleteDevice(id);
    }
}
