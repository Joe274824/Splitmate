package SplitMate.service;

import SplitMate.domain.User;
import SplitMate.mapper.UserMapper;
import SplitMate.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
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

    @Autowired
    private JavaMailSender mailSender;

    @Autowired
    private JwtUtil jwtUtil;

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

    private String getFileExtension(String fileName) {
        if (fileName.lastIndexOf(".") != -1 && fileName.lastIndexOf(".") != 0) {
            return fileName.substring(fileName.lastIndexOf("."));
        } else {
            return "";
        }
    }

    public void savePhotos(Long userId, List<MultipartFile> photos) throws IOException {
        String directoryPath = "user-photos/" + userId;
        File directory = new File(directoryPath);

        if (!directory.exists()) {
            directory.mkdirs();
        }

        for (int i = 0; i < photos.size(); i++) {
            MultipartFile photo = photos.get(i);
            String fileName = "photo" + (i + 1) + getFileExtension(photo.getOriginalFilename());
            File destinationFile = new File(directory, fileName);
            photo.transferTo(destinationFile);
        }
    }

    public void sendPasswordResetEmail(String email) {
        User user = userMapper.findByEmail(email);
        if (user == null) {
            throw new IllegalArgumentException("Email address not found");
        }

        String token = jwtUtil.generateToken(user.getUsername());
        String resetUrl = "http://120.26.0.31:8080/users/reset-password?token=" + token;

        // 发送邮件
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(email);
        message.setSubject("Password Reset Request");
        message.setText("To reset your password, click the link below:\n" + resetUrl);

        mailSender.send(message);
    }

    public void resetPassword(String token, String newPassword) {
        if (jwtUtil.isTokenExpired(token)) {
            throw new IllegalArgumentException("Invalid or expired password reset token.");
        }

        // 从 JWT 中提取邮箱
        String username = jwtUtil.extractUsername(token);
        User user = userMapper.findByUsername(username);
        if (user == null) {
            throw new IllegalArgumentException("User not found.");
        }

        // 加密新密码
        user.setPassword(passwordEncoder.encode(newPassword));
        userMapper.updateUser(user);
    }
}
