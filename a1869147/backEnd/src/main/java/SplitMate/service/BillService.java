package SplitMate.service;

import SplitMate.domain.*;
import SplitMate.mapper.BillMapper;
import SplitMate.mapper.PaymentRecordMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;


import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class BillService {

    @Autowired
    private UserService userService;

    @Autowired
    private BillMapper billMapper;

    @Autowired
    private MinioService minioService;
    @Autowired
    private DeviceUsageService deviceUsageService;
    @Autowired
    private PaymentRecordMapper paymentRecordMapper;
    @Autowired
    private DeviceService deviceService;

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

    public void updateBill(Bill bill) {
        billMapper.updateBill(bill);
    }

    public Bill getBillById(Long id) {
        return billMapper.getBillById(id);
    }

    public void generatePayment(Bill bill, List<HouseTenant> tenants) {
        BigDecimal totalAmount = bill.getBillPrice();
        System.out.println("totalAmount:" + totalAmount);
        HashMap<Integer, List<DeviceUsage>> record = new HashMap<>();
        String billDate = bill.getBillDate();

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM/yyyy");
        YearMonth yearMonth = YearMonth.parse(billDate, formatter);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();

        for (HouseTenant tenant : tenants) {
            List<DeviceUsage> deviceUsageByMonth = deviceUsageService.getDeviceUsageByMonth((long) tenant.getUserId(), startDate, endDate);
            System.out.println(deviceUsageByMonth.size());
            record.put(tenant.getUserId(), deviceUsageService.getDeviceUsageByMonth((long) tenant.getUserId(), startDate, endDate));
        }

        HashMap<Integer, BigDecimal> result = new HashMap<>();
        for (HouseTenant tenant : tenants) {
            List<DeviceUsage> deviceUsages = record.get(tenant.getUserId());
            if (deviceUsages.isEmpty()) {
                result.put(tenant.getUserId(), BigDecimal.valueOf(0));
            }
            int result1 = 0;
            for (int i = 0; i < deviceUsages.size(); i++) {
                DeviceUsage deviceUsage = deviceUsages.get(i);
                if (!deviceUsage.getDevice().getCategory().equals(bill.getCategory())) {
                    continue;
                }
                System.out.println(deviceUsage.toString());
                Device device = deviceService.getDeviceById(deviceUsage.getDevice().getId());
                System.out.println("power:" + device.getPower());
                System.out.println("Time:" + deviceUsage.getUsageTime());
                result1 += device.getPower() * deviceUsage.getUsageTime();
                System.out.println(result1);
            }
            result.put(tenant.getUserId(), BigDecimal.valueOf(result1));
        }
        BigDecimal totalUsage = result.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        for (Map.Entry<Integer, BigDecimal> entry : result.entrySet()) {
            Integer id = entry.getKey();
            BigDecimal consumption = entry.getValue();

            BigDecimal ratio = totalUsage.compareTo(BigDecimal.ZERO) > 0
                    ? consumption.divide(totalUsage, 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            System.out.println("id:" + id);
            System.out.println("ratio:" + ratio);
            BigDecimal paymentAmount = ratio.multiply(totalAmount).setScale(2, RoundingMode.HALF_UP);

            PaymentRecord paymentRecord = new PaymentRecord();
            paymentRecord.setAmount(paymentAmount);
            paymentRecord.setOwnerId(bill.getUserId().intValue());
            paymentRecord.setHouseId(bill.getHouseId().intValue());
            paymentRecord.setUserId(id);
            paymentRecord.setBillMonth(billDate);
            paymentRecord.setCategory(bill.getCategory());
            paymentRecord.setPaid(false);

            paymentRecordMapper.insertPaymentRecord(paymentRecord);  // 插入数据库
        }


    }
}
