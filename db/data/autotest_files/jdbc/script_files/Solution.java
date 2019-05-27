import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public abstract class Solution extends JDBCSubmission {

    public Solution() throws ClassNotFoundException {

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

    public List<String> select(Double numberThreshold) {

        try {
            String sql = "SELECT table1.word FROM table1 JOIN table2 ON table1.id = table2.foreign_id WHERE " +
                         "table2.number > ?";
            PreparedStatement statement = this.connection.prepareStatement(sql);
            statement.setDouble(1, numberThreshold);
            ResultSet resultSet = statement.executeQuery();
            List<String> result = new ArrayList<>();
            while (resultSet.next()) {
                result.add(resultSet.getString(1));
            }
            statement.close();

            return result;
        }
        catch (Exception e) {
            return null;
        }
    }

    public boolean insert(String newWord) {

        // only CorrectNoOrder.insert() should insert the correct tuple
        // in a real assignment with multiple files there should not be competing functions
        return true;
    }

}
