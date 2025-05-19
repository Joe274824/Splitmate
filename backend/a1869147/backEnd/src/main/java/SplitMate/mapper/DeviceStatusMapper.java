package SplitMate.mapper;

import SplitMate.domain.DeviceStatus;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface  DeviceStatusMapper {

    DeviceStatus getDeviceStatusById(Long id);
    DeviceStatus getDeviceStatusByName(String name);

    int insertDeviceStatus(DeviceStatus deviceStatus);

    int updateDeviceStatus(DeviceStatus deviceStatus);

    int deleteDeviceStatus(Long id);

}
