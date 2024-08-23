package SplitMate.controller;

import SplitMate.domain.DeviceUsage;
import SplitMate.service.DeviceUsageService;
import SplitMate.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/deviceUsages")
public class DeviceUsageController {

    @Autowired
    private DeviceUsageService deviceUsageService;

    @Autowired
    private JwtUtil jwtUtil;

    @GetMapping
    public List<DeviceUsage> getAllDeviceUsages() {
        return deviceUsageService.getAllDeviceUsages();
    }

    @GetMapping("/{id}")
    public DeviceUsage getDeviceUsageById(@PathVariable Long id) {
        return deviceUsageService.getDeviceUsageById(id);
    }

    @PostMapping
    public void createDeviceUsage(@RequestBody DeviceUsage deviceUsage) {
        deviceUsageService.createDeviceUsage(deviceUsage);
    }

    @GetMapping("/username")
    public List<DeviceUsage> getDeviceUsageByUserID(@RequestHeader("Authorization") String token) {
        String jwtToken = token.substring(7);

        // 使用 JwtUtil 解析用户名
        String username = jwtUtil.extractUsername(jwtToken);

        // 使用用户名进行查询
        return deviceUsageService.getDeviceUsageByUsername(username);
    }

    @PutMapping("/{id}")
    public void updateDeviceUsage(@PathVariable Long id, @RequestBody DeviceUsage deviceUsage) {
        deviceUsage.setId(id);
        deviceUsageService.updateDeviceUsage(deviceUsage);
    }

    @DeleteMapping("/{id}")
    public void deleteDeviceUsage(@PathVariable Long id) {
        deviceUsageService.deleteDeviceUsage(id);
    }
}