package SplitMate.service;

import SplitMate.domain.Device;
import SplitMate.domain.DeviceStatus;
import SplitMate.mapper.DeviceMapper;
import SplitMate.mapper.DeviceStatusMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

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
}
