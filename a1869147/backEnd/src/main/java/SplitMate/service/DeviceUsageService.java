package SplitMate.service;

import SplitMate.domain.DeviceUsage;
import SplitMate.mapper.DeviceUsageMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DeviceUsageService {

    @Autowired
    private DeviceUsageMapper deviceUsageMapper;

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
}