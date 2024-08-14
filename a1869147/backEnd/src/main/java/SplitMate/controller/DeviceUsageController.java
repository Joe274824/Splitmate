package SplitMate.controller;

import SplitMate.domain.DeviceUsage;
import SplitMate.service.DeviceUsageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/deviceUsages")
public class DeviceUsageController {

    @Autowired
    private DeviceUsageService deviceUsageService;

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