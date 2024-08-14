package SplitMate.service;

import SplitMate.domain.Device;
import SplitMate.mapper.DeviceMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DeviceService {

    @Autowired
    private DeviceMapper deviceMapper;

    public List<Device> getAllDevices() {
        return deviceMapper.getAllDevices();
    }

    public Device getDeviceById(Long id) {
        return deviceMapper.getDeviceById(id);
    }

    public void createDevice(Device device) {
        deviceMapper.insertDevice(device);
    }

    public void updateDevice(Device device) {
        deviceMapper.updateDevice(device);
    }

    public void deleteDevice(Long id) {
        deviceMapper.deleteDevice(id);
    }
}
