import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class CorrectNoOrder extends Submission {

    public CorrectNoOrder() throws ClassNotFoundException {

        super();
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

        try {
            String sql = "INSERT INTO table1(id, word) VALUES (?, ?)";
            PreparedStatement statement = this.connection.prepareStatement(sql);
            statement.setInt(1, 3);
            statement.setString(2, newWord);
            statement.executeUpdate();
            statement.close();

            return true;
        }
        catch (Exception e) {
            return false;
        }
    }

}
