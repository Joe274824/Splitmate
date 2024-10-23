package SplitMate.service;

import io.minio.*;
import io.minio.messages.Item;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Service
public class MinioService {

    @Autowired
    private MinioClient minioClient;

    public void uploadFile(String bucketName, String objectName, InputStream stream, String contentType, long size) throws Exception {
        minioClient.putObject(
                PutObjectArgs.builder()
                        .bucket(bucketName)
                        .object(objectName)
                        .stream(stream, size, -1)
                        .contentType(contentType)
                        .build()
        );
    }

    // 下载文件
    public InputStream downloadFile(String bucketName, String objectName) throws Exception {
        return minioClient.getObject(
                GetObjectArgs.builder()
                        .bucket(bucketName)
                        .object(objectName)
                        .build()
        );
    }

    public MediaType getMediaType(String fileName) {
        String fileExtension = getFileExtension(fileName).toLowerCase();

        switch (fileExtension) {
            case ".jpg":
            case ".jpeg":
                return MediaType.IMAGE_JPEG;
            case ".png":
                return MediaType.IMAGE_PNG;
            case ".gif":
                return MediaType.IMAGE_GIF;
            case ".pdf":
                return MediaType.APPLICATION_PDF;
            case ".txt":
                return MediaType.TEXT_PLAIN;
            default:
                return MediaType.APPLICATION_OCTET_STREAM; // 默认类型
        }
    }

    public String getFileExtension(String originalFilename) {
        return originalFilename.substring(originalFilename.lastIndexOf("."));
    }

    public String getFileContentType(String bucketName, String objectName) throws Exception{
        StatObjectResponse stat = minioClient.statObject(StatObjectArgs.builder()
                .bucket(bucketName)
                .object(objectName)
                .build());
        return stat.contentType();
    }

    public List<String> listUserPhotos(String bucketName, Long userId) throws Exception {
        String prefix = "user_photo_" + userId + "_";
        List<String> fileNames = new ArrayList<>();

        Iterable<Result<Item>> objects = minioClient.listObjects(
                ListObjectsArgs.builder()
                        .bucket(bucketName)
                        .prefix(prefix)
                        .recursive(true)
                        .build()
        );

        for (Result<Item> result : objects) {
            Item item = result.get();
            fileNames.add(item.objectName());
        }

        return fileNames;
    }
}
