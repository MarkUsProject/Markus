import java.sql.DriverManager;
import java.sql.SQLException;

public abstract class Submission extends JDBCSubmission {

    public Submission() throws ClassNotFoundException {

        Class.forName("org.postgresql.Driver");
    }

    @Override
    public boolean connectDB(String url, String username, String password) {

        try {
            this.connection = DriverManager.getConnection(url, username, password);
            return true;
        }
        catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean disconnectDB() {

        try {
            this.connection.close();
            return true;
        }
        catch (SQLException e) {
            return false;
        }
    }

}
