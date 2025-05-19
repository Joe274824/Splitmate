package SplitMate.mapper;

import SplitMate.domain.Device;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface DeviceMapper {
    /**
     * Retrieves all devices.
     * @return a list of all devices.
     */
    List<Device> getAllDevices();

    /**
     * Retrieves a device by its ID.
     * @param id the ID of the device.
     * @return the device with the specified ID.
     */
    Device getDeviceById(Long id);

    /**
     * Inserts a new device into the database.
     * @param device the device to be inserted.
     */
    void insertDevice(Device device);

    /**
     * Updates an existing device in the database.
     * @param device the device with updated details.
     */
    void updateDevice(Device device);

    /**
     * Deletes a device by its ID.
     * @param id the ID of the device to be deleted.
     */
    void deleteDevice(Long id);

    Device getDeviceByName(String name);

    Device getDeviceByBLEAddress(String bleAddress);
}