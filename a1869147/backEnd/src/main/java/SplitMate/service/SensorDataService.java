package SplitMate.service;

import SplitMate.domain.SensorData;
import SplitMate.mapper.SensorDataMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SensorDataService {

    @Autowired
    private SensorDataMapper sensorDataMapper;

    public void saveSensorData(SensorData sensorData) {
        sensorDataMapper.insertSensorData(sensorData);
    }

    public void deleteSensorData(Long id) {
        sensorDataMapper.deleteSensorData(id);
    }

    public SensorData getSensorDataById(Long id) {
        return sensorDataMapper.selectSensorDataById(id);
    }

    public List<SensorData> getAllSensorData() {
        return sensorDataMapper.selectAllSensorData();
    }
}

