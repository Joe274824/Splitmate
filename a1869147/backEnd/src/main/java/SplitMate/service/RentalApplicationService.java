package SplitMate.service;


import SplitMate.domain.RentalApplication;
import SplitMate.mapper.RentalApplicationMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RentalApplicationService {

    @Autowired
    private RentalApplicationMapper rentalApplicationMapper;

    public boolean submitApplication(Long userId, Long houseId) {
        // 创建申请记录
        RentalApplication application = new RentalApplication();
        application.setUserId(userId);
        application.setHouseId(houseId);
        application.setStatus(0);  // 申请状态为待审批

        // 插入申请记录
        rentalApplicationMapper.insertApplication(application);
        return true;
    }

    public RentalApplication getApplicationById(Long id) {
        return rentalApplicationMapper.getApplicationById(id);
    }

    public boolean updateApplicationStatus(Long id, int status) {
        rentalApplicationMapper.updateApplicationStatus(id, status);
        return true;
    }

    public List<RentalApplication> getPendingApplications(Long id) {
        return rentalApplicationMapper.getPendingApplications(id);
    }
}

