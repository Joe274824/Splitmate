package SplitMate.mapper;

import SplitMate.domain.Bluetooth;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface BluetoothMapper {
    void insertBluetooth(Bluetooth bluetooth);

    Bluetooth getBluetoothByMacAddress(String macAddress);

    List<Bluetooth> getBluetoothByUsername(String username);

    void updateLastConnectedTime(String macAddress, Bluetooth bluetooth);

    void deleteBluetooth(String macAddress);
}
