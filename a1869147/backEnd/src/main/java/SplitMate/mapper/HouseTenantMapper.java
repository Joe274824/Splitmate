package SplitMate.mapper;

import SplitMate.domain.HouseTenant;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface HouseTenantMapper {

    List<HouseTenant> getTenantsByHouseId(int houseId);

    HouseTenant getHouseIdByTenantId(int tenantId);

    void insertHouseTenant(Long houseId, Long userId);
}

