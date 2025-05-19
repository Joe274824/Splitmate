package SplitMate.service;

import SplitMate.domain.*;
import SplitMate.mapper.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Service
public class BluetoothService {

    @Autowired
    private DeviceMapper deviceMapper;
    @Autowired
    public UserMapper userMapper;
    @Autowired
    private BluetoothMapper bluetoothMapper;
    @Autowired
    private DeviceUsageMapper deviceUsageMapper;
    @Autowired
    public DeviceStatusMapper deviceStatusMapper;

    public void addBluetooth(Bluetooth bluetooth) {
        bluetoothMapper.insertBluetooth(bluetooth);
    }

    public Bluetooth getBluetoothByMacAddress(String macAddress) {
        return bluetoothMapper.getBluetoothByMacAddress(macAddress);
    }

    public List<Bluetooth> getBluetoothByUsername(String username) {
        return bluetoothMapper.getBluetoothByUsername(username);
    }

    public void updateLastConnectedTime(String macAddress, Bluetooth bluetooth) {
        bluetoothMapper.updateLastConnectedTime(macAddress, bluetooth);
    }

    public void deleteBluetooth(String macAddress) {
        bluetoothMapper.deleteBluetooth(macAddress);
    }

    public boolean addUsage(String macAddress, String BLEAddress) {
        try {
            Device device = deviceMapper.getDeviceByBLEAddress(BLEAddress);
            Bluetooth bluetooth = bluetoothMapper.getBluetoothByMacAddress(macAddress);
            DeviceUsage deviceUsage = new DeviceUsage();
            deviceUsage.setDevice(device);
            User user = userMapper.findByUsername(bluetooth.getUsername());
            deviceUsage.setUser(user);
            DeviceStatus status = deviceStatusMapper.getDeviceStatusByName(device.getName());
            if (Objects.equals(status.getDeviceStatus(), "0")) {
                System.out.println("device:" + device.getName() + " open");
                deviceUsage.setStartTime(new Timestamp(System.currentTimeMillis()));
                status.setDeviceStatus("1");
                deviceStatusMapper.updateDeviceStatus(status);
                deviceUsageMapper.insertDeviceUsage(deviceUsage);
                System.out.println("save successful！");
            } else {
                System.out.println("device:" + device.getName() + " close");
                status.setDeviceStatus("0");
                deviceStatusMapper.updateDeviceStatus(status);
                DeviceUsage deviceUsageByDeviceId = deviceUsageMapper.getDeviceUsageByDeviceId(device.getId());
                Timestamp startTime = deviceUsageByDeviceId.getStartTime();
                LocalDateTime startTime1 = startTime.toLocalDateTime();
                LocalDateTime endTime = LocalDateTime.now();
                deviceUsageByDeviceId.setEndTime(Timestamp.valueOf(endTime));
                long usageTime = Duration.between(startTime1, endTime).getSeconds() / 60;
                deviceUsageByDeviceId.setUsageTime(Math.toIntExact(usageTime));
                deviceUsageMapper.updateDeviceUsage(deviceUsageByDeviceId);
                System.out.println("save successful！");
            }
        } catch (Exception e) {
            return false;
        }
        return true;
    }

}