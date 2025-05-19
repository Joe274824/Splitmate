package SplitMate.controller;

public class AuthenticationRequest {
    private String username;
    private String password;
    private String userPhoneID;

    public String getUserPhoneID() {
        return userPhoneID;
    }

    public void setUserPhoneID(String userPhoneID) {
        this.userPhoneID = userPhoneID;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
