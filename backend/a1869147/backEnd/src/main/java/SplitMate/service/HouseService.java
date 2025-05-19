package SplitMate.service;


import SplitMate.domain.House;
import SplitMate.domain.HouseTenant;
import SplitMate.mapper.HouseMapper;
import SplitMate.mapper.HouseTenantMapper;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;


import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Objects;


@Service
public class HouseService {

    @Autowired
    private HouseTenantMapper houseTenantMapper;

    @Autowired
    private HouseMapper houseMapper;

    @Autowired
    private DeviceService deviceService;

    @Autowired
    private MinioService minioService;

    public void addHouse(House house) {
        houseMapper.insertHouse(house);
    }

    public void uploadHousePhoto(MultipartFile file, int houseId) throws IOException {
        House house = houseMapper.selectHouseById(houseId);
        // 2. 后续处理逻辑（生成文件名、上传到 Minio 等）
        String originalFileName = file.getOriginalFilename();
        String fileExtension = deviceService.getFileExtension(Objects.requireNonNull(originalFileName));
        String fileName = "house_photo_" + houseId + fileExtension;

        // 上传文件到 Minio
        String bucketName = "house-images";
        InputStream fileStream = file.getInputStream();
        long fileSize = file.getSize();
        String contentType = minioService.getMediaType(originalFileName).toString();
        try {
            minioService.uploadFile(bucketName, fileName, fileStream, contentType, fileSize);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        // 5. 更新房屋信息中的 imagePath
        String imagePath = "house-images/" + fileName;
        house.setHouseImagePath(imagePath);
        houseMapper.updateHouse(house);

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

    public ResponseEntity<Resource> downloadHousePhoto(int houseId){
        try {
            // 根据房屋 ID 获取房屋信息
            House house = houseMapper.selectHouseById(houseId);
            if (house == null || house.getHouseImagePath() == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }

            // 获取照片的对象名
            String objectName = house.getHouseImagePath().substring(house.getHouseImagePath().indexOf("/") + 1);

            // 获取文件的内容类型
            MediaType mediaType = minioService.getMediaType(objectName);

            // 从 MinIO 下载文件
            InputStream photoStream = minioService.downloadFile("house-images", objectName);
            if (photoStream == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }

            Resource resource = new InputStreamResource(photoStream);

            return ResponseEntity.ok()
                    .contentType(mediaType) // 根据实际内容类型设置
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"") // 设置Content-Disposition为inline
                    .body(resource);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
}
