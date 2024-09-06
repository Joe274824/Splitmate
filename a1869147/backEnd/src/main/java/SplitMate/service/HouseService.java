package SplitMate.service;


import SplitMate.domain.House;
import SplitMate.domain.HouseTenant;
import SplitMate.mapper.HouseMapper;
import SplitMate.mapper.HouseTenantMapper;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;


import java.util.List;


@Service
public class HouseService {

    @Autowired
    private HouseTenantMapper houseTenantMapper;

    @Autowired
    private HouseMapper houseMapper;

    public void addHouse(House house) {
        houseMapper.insertHouse(house);
    }

    public void updateHouse(House house) {
        houseMapper.updateHouse(house);
    }

    public void deleteHouse(int houseId) {
        houseMapper.deleteHouse(houseId);
    }

    public House getHouseById(int houseId) {
        return houseMapper.selectHouseById(houseId);
    }

    public List<House> getAllHouses() {
        return houseMapper.selectAllHouses();
    }

    public HouseTenant getHouseIdByTenantId(int tenantId) {
        return houseTenantMapper.getHouseIdByTenantId(tenantId);
    }

    public List<HouseTenant> getHouseTenantByHouseId(int houseId) {
        return houseTenantMapper.getTenantsByHouseId(houseId);
    }

    public List<House> getHousesByStatus(int status) {
        return houseMapper.selectHousesByStatus(status);
    }

    public List<House> getHousesByLandLordName(String name) {
        return houseMapper.selectHousesByLandLordName(name);
    }

    public List<House> getHouseIdByLandlordId(Long id) {
        return houseMapper.selectHousesByLandLordId(id);
    }
}
