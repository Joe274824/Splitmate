package SplitMate.mapper;

import SplitMate.domain.User;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface UserMapper {
    /**
     * Retrieves all users.
     * @return a list of all users.
     */
    List<User> getAllUsers();

    /**
     * Retrieves a user by their ID.
     * @param id the ID of the user.
     * @return the user with the specified ID.
     */
    User getUserById(Long id);

    /**
     * Inserts a new user into the database.
     * @param user the user to be inserted.
     */
    void insertUser(User user);

    /**
     * Updates an existing user in the database.
     * @param user the user with updated details.
     */
    void updateUser(User user);

    /**
     * Deletes a user by their ID.
     * @param id the ID of the user to be deleted.
     */
    void deleteUser(Long id);

    User findByUsername(String username);

    User findByEmail(String email);
}

