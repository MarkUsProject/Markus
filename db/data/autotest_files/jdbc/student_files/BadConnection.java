import java.sql.DriverManager;
import java.sql.SQLException;

public class BadConnection extends Submission {

    public BadConnection() throws ClassNotFoundException {

        super();
    }

    @Override
    public boolean connectDB(String url, String username, String password) {

        try {
            this.connection = DriverManager.getConnection(url, username, password);
            this.disconnectDB();
            return true;
        }
        catch (SQLException e) {
            return false;
        }
    }

}
