package SplitMate.mapper;


import SplitMate.domain.SensorData;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface SensorDataMapper {

    void insertSensorData(SensorData sensorData);

    void updateSensorData(SensorData sensorData);

    void deleteSensorData(@Param("id") Long id);

    SensorData selectSensorDataById(@Param("id") Long id);

    List<SensorData> selectAllSensorData();
}
