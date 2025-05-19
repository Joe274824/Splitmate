package SplitMate.domain;

public class RentalApplicationWithUserDTO {
    private RentalApplication rentalApplication;
    private User user;

    public RentalApplicationWithUserDTO(RentalApplication application, User user1) {
        this.rentalApplication = application;
        this.user = user1;
    }

    // Getter 和 Setter 方法
    public RentalApplication getRentalApplication() {
        return rentalApplication;
    }

    public void setRentalApplication(RentalApplication rentalApplication) {
        this.rentalApplication = rentalApplication;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }
}
