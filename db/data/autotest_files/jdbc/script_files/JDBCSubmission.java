import java.sql.Connection;

public abstract class JDBCSubmission {

    /**
     * The connection used for this session.
     */
    public Connection connection;

    /**
     * Establishes a connection to the database, assigning it to the instance variable
     * {@link JDBCSubmission#connection}.
     *
     * @param url The database url.
     * @param username The username to connect to the database.
     * @param password The password to connect to the database.
     * @return True if connecting is successful, false otherwise.
     */
    public abstract boolean connectDB(String url, String username, String password);

    /**
     * Closes the database connection.
     *
     * @return True if closing was successful, false otherwise.
     */
    public abstract boolean disconnectDB();

}
