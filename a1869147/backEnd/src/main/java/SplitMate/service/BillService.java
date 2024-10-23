package SplitMate.service;

import SplitMate.domain.Bill;
import SplitMate.domain.User;
import SplitMate.mapper.BillMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;


import java.io.IOException;
import java.io.InputStream;
import java.util.List;

@Service
public class BillService {

    @Autowired
    private UserService userService;

    @Autowired
    private BillMapper billMapper;

    @Autowired
    private MinioService minioService;

    // 检查用户是否为主租户
    public boolean isMainTenant(Long userId) {
        // 从 UserService 中获取用户
        User user = userService.getUserById(userId);
        // 判断是否为主租户
        return user.getUserType() == 1;
    }

    // 保存账单文件
    public void saveBill(MultipartFile file, Bill bill) throws IOException {
        String fileName = System.currentTimeMillis() + "_" + file.getOriginalFilename();
        String bucketName = "bill";
        String contentType = minioService.getMediaType(fileName).toString();
        try {
            minioService.uploadFile(bucketName, fileName, file.getInputStream(), contentType, file.getSize());
        } catch (Exception e) {
            throw new IOException("Failed to upload bill: " + e.getMessage(), e);
        }

        bill.setFileName(fileName);
        bill.setFilePath("bill/" + fileName);
        billMapper.insertBill(bill);
    }

    // 查询所有可下载的账单
    public List<Bill> getAllBills(Long houseId) {
        return billMapper.getAllBills(houseId);
    }

    // 加载指定的 PDF 文件
    public Resource loadBillAsResource(Long billId) {
        Bill bill = billMapper.getBillById(billId);
        if (bill == null) {
            throw new RuntimeException("Bill not found for ID: " + billId);
        }
        String filePath = bill.getFilePath();
        String bucketName = "bill";
        String objectName = filePath.substring(filePath.indexOf("/") + 1);

        try {
            InputStream inputStream = minioService.downloadFile(bucketName, objectName);
            return new InputStreamResource(inputStream);
        } catch (Exception e) {
            throw new RuntimeException("Could not load file from Minio: " + e.getMessage(), e);
        }
    }
}
