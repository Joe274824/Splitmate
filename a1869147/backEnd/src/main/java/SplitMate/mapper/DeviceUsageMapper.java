package SplitMate.mapper;

import SplitMate.domain.DeviceUsage;
import org.apache.ibatis.annotations.*;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface DeviceUsageMapper {
    /**
     * Retrieves all device usage records.
     * @return a list of all device usage records.
     */
    List<DeviceUsage> getAllDeviceUsages();

    /**
     * Retrieves a device usage record by its ID.
     * @param id the ID of the device usage record.
     * @return the device usage record with the specified ID.
     */
    DeviceUsage getDeviceUsageById(Long id);

    /**
     * Inserts a new device usage record into the database.
     * @param deviceUsage the device usage record to be inserted.
     */
    void insertDeviceUsage(DeviceUsage deviceUsage);

    /**
     * Updates an existing device usage record in the database.
     * @param deviceUsage the device usage record with updated details.
     */
    void updateDeviceUsage(DeviceUsage deviceUsage);

    /**
     * Deletes a device usage record by its ID.
     * @param id the ID of the device usage record to be deleted.
     */
    void deleteDeviceUsage(Long id);

    List<DeviceUsage> getDeviceUsageByUsername(String username);

    List<DeviceUsage> findUpdatedDataSince(String timestamp);

    List<DeviceUsage> getDeviceUsageByMonth(@Param("userId") Long userId,
                                            @Param("startOfMonth") LocalDate startOfMonth,
                                            @Param("endOfMonth") LocalDate endOfMonth);

    DeviceUsage getDeviceUsageByDeviceId(Long id);

    DeviceUsage getFirstUsageByHouseId(int houseId);
}
