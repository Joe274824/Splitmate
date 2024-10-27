package SplitMate.controller;

import SplitMate.domain.User;
import SplitMate.service.MinioService;
import SplitMate.service.UserService;
import SplitMate.util.JwtUtil;
import io.swagger.annotations.ApiParam;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/users")
public class UserController {

    @Autowired
    private UserService userService;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private MinioService minioService;

    @GetMapping
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        User user = userService.getUserById(id);
        return user != null ? ResponseEntity.ok(user) : ResponseEntity.notFound().build();
    }

    @GetMapping("/findUser")
    public ResponseEntity<User> getUser(@RequestHeader("Authorization") @ApiParam(required = false)String token) {
        String jwtToken = token.substring(7);
        // 使用 JwtUtil 解析用户名
        String username = jwtUtil.extractUsername(jwtToken);
        User user = userService.getUserByUsername(username);
        return user != null ? ResponseEntity.ok(user) : ResponseEntity.notFound().build();
    }

    @PostMapping("/create")
    public ResponseEntity<String> createUser(@RequestBody User user) {
        try {
            User existingUser = userService.getUserByUsername(user.getUsername());
            if (existingUser != null) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body("Username has already been used");
            }
            userService.createUser(user);
            return ResponseEntity.status(HttpStatus.CREATED).body("User created successfully");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Failed to create user: " + e.getMessage());
        }
    }

    @PostMapping(value = "/uploadPhotos", consumes = "multipart/form-data")
    public ResponseEntity<String> uploadPhotos(@RequestParam("username") String username,
                                               @RequestParam("photo1") MultipartFile photo1,
                                               @RequestParam("photo2") MultipartFile photo2,
                                               @RequestParam("photo3") MultipartFile photo3) {
        System.out.println("Received username: " + username);
        ArrayList<MultipartFile> photos = new ArrayList<>();
        photos.add(photo1);
        photos.add(photo2);
        photos.add(photo3);
        System.out.println("Number of photos: " + photos.size());
        User user = userService.getUserByUsername(username);
        if (user == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("User not found");
        }
        Long userId = user.getId();
        try {
            for (MultipartFile photo : photos) {
                if (photo.isEmpty()) {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("One of the photos is empty");
                }
            }
            userService.savePhotos(userId, photos);
            return ResponseEntity.status(HttpStatus.CREATED).body("Photos uploaded successfully");

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to upload photos: " + e.getMessage());
        }
    }

    @GetMapping("/users/{userId}/photo")
    public ResponseEntity<List<Resource>> downloadUserPhoto(@PathVariable Long userId) {
        String bucketName = "user-images";
        try {
            List<String> photoFiles = minioService.listUserPhotos(bucketName, userId);
            List<Resource> resources = new ArrayList<>();
            for (String fileName : photoFiles) {
                InputStream photoStream = minioService.downloadFile(bucketName, fileName);
                if (photoStream != null) {
                    Resource resource = new InputStreamResource(photoStream);
                    resources.add(resource);
                }
            }
            return ResponseEntity.ok(resources);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> updateUser(@PathVariable Long id, @RequestBody User user) {
        user.setId(id);
        userService.updateUser(user);
        return ResponseEntity.ok("User updated successfully");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.ok("User deleted successfully");
    }

    // 找回密码接口，发送重置链接到用户邮箱
    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestParam String email) {
        try {
            userService.sendPasswordResetEmail(email);
            return ResponseEntity.ok("Password reset link has been sent to your email.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Failed to send password reset email: " + e.getMessage());
        }
    }

    @GetMapping("/reset-password")
    public String showResetPasswordPage(@RequestParam("token") String token, Model model) {
        model.addAttribute("token", token);
        return "reset-password"; // 返回 reset-password.html
    }

    @PostMapping("/reset-password")
    public String resetPassword(@RequestParam String token,
                                @RequestParam String newPassword,
                                @RequestParam String confirmPassword,
                                Model model) {

        if (!newPassword.equals(confirmPassword)) {
            model.addAttribute("message", "Passwords do not match.");
            return "reset-password";
        }

        try {
            System.out.println(newPassword);
            userService.resetPassword(token, newPassword); // 实现密码重置
            model.addAttribute("message", "Password reset successfully. You can close this page and log in from the app.");
            return "reset-password";
        } catch (Exception e) {
            model.addAttribute("message", "Failed to reset password: " + e.getMessage());
            return "reset-password";
        }
    }
}
