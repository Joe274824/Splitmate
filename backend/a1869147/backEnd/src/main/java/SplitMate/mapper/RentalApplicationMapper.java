package SplitMate.mapper;


import SplitMate.domain.RentalApplication;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface RentalApplicationMapper {

    // 插入申请
    void insertApplication(RentalApplication application);

    // 根据 ID 获取申请
    RentalApplication getApplicationById(@Param("id") Long id);

    // 更新申请状态
    void updateApplicationStatus(@Param("id") Long id, @Param("status") int status);

    // 获取待审批的申请
    List<RentalApplication> getPendingApplications(Long id);

    RentalApplication getApplicationByUserAndHouse(Long userId, Long houseId);
}
