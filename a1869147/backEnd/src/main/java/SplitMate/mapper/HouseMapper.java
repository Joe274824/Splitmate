package SplitMate.mapper;

import SplitMate.domain.House;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface HouseMapper {

    // 插入
    void insertHouse(House house);

    // 更新
    void updateHouse(House house);

    // 删除
    void deleteHouse(@Param("houseId") int houseId);

    // 查询单个
    House selectHouseById(@Param("houseId") int houseId);

    // 查询所有
    List<House> selectAllHouses();

    // 查询 house_status 为 1 的房屋
    List<House> selectHousesByStatus(int status);
}
