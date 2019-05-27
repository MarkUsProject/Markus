import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class BadSelect extends Submission {

    public BadSelect() throws ClassNotFoundException {

        super();
    }

    public List<String> select(Double numberThreshold) {

        try {
            String sql = "SELECT CONCAT(table1.word, 'X') AS word FROM table1 JOIN table2 " +
                         "ON table1.id = table2.foreign_id WHERE table2.number > ?";
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

}
