package SplitMate.service;

import SplitMate.domain.Bill;
import SplitMate.domain.User;
import SplitMate.mapper.BillMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;


import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@Service
public class BillService {

    @Autowired
    private UserService userService;

    @Autowired
    private BillMapper billMapper;

    // 检查用户是否为主租户
    public boolean isMainTenant(Long userId) {
        // 从 UserService 中获取用户
        User user = userService.getUserById(userId);
        // 判断是否为主租户
        return user.getUserType() == 1;
    }

    // 保存账单文件
    public void saveBill(MultipartFile file, Long userId) throws IOException {
        // 将文件保存到指定目录或数据库
        String fileName = System.currentTimeMillis() + "_" + file.getOriginalFilename(); // 加上时间戳避免冲突
        String uploadDir = "uploads/" + userId;

        // 创建文件目录
        File dir = new File(uploadDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        // 保存文件
        Path filePath = Paths.get(uploadDir, fileName);
        Files.write(filePath, file.getBytes());

        // 保存文件信息到数据库
        Bill bill = new Bill();
        bill.setUserId(userId);
        bill.setFileName(fileName);
        bill.setFilePath(filePath.toString());
        billMapper.insertBill(bill);
    }

    // 查询所有可下载的账单
    public List<Bill> getAllBills() {
        return billMapper.getAllBills();
    }

    // 加载指定的 PDF 文件
    public Resource loadBillAsResource(Long billId) {
        Bill bill = billMapper.getBillById(billId);
        Path filePath = Paths.get(bill.getFilePath()).normalize().toAbsolutePath();
        try {
            return new UrlResource(filePath.toUri());
        } catch (MalformedURLException e) {
            throw new RuntimeException("Could not read file", e);
        }
    }
}
