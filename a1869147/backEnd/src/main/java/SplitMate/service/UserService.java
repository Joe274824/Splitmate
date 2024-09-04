package SplitMate.service;

import SplitMate.domain.User;
import SplitMate.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.List;

@Service
public class UserService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public List<User> getAllUsers() {
        return userMapper.getAllUsers();
    }

    public User getUserById(Long id) {
        return userMapper.getUserById(id);
    }

    public void createUser(User user) {
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        user.setStatus("active");
        userMapper.insertUser(user);
    }

    public void updateUser(User user) {
        userMapper.updateUser(user);
    }

    public void deleteUser(Long id) {
        userMapper.deleteUser(id);
    }

    public User getUserByUsername(String username) {
        return userMapper.findByUsername(username);
    }

    public void createUserWithPhotos(User user, MultipartFile[] photos) throws IOException {
        // 检查用户名是否已存在
        User existingUser = userMapper.findByUsername(user.getUsername());
        if (existingUser != null) {
            throw new IllegalArgumentException("Username has already been used");
        }

        // 创建新用户
        userMapper.insertUser(user);

        // 获取新用户的ID
        Long userId = user.getId();

        // 创建以用户ID命名的文件夹
        String userFolder = "user-photos/" + userId;
        File dir = new File(userFolder);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        // 保存照片到用户文件夹
        for (int i = 0; i < photos.length; i++) {
            MultipartFile photo = photos[i];
            String fileName = "photo" + (i + 1) + getFileExtension(photo.getOriginalFilename());
            File destinationFile = new File(dir, fileName);
            photo.transferTo(destinationFile);
        }
    }

    private String getFileExtension(String fileName) {
        if (fileName.lastIndexOf(".") != -1 && fileName.lastIndexOf(".") != 0) {
            return fileName.substring(fileName.lastIndexOf("."));
        } else {
            return "";
        }
    }

    public void savePhotos(Long userId, List<MultipartFile> photos) throws IOException {
        String directoryPath = "path_to_directory/" + userId;
        File directory = new File(directoryPath);

        if (!directory.exists()) {
            directory.mkdirs();
        }

        for (int i = 0; i < photos.size(); i++) {
            String filePath = directoryPath + "/" + "photo" + (i + 1) + ".jpg";
            photos.get(i).transferTo(new File(filePath));
        }
    }
}
