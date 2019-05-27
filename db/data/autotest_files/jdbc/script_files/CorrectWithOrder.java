import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class CorrectWithOrder extends Solution {

    public CorrectWithOrder() throws ClassNotFoundException {

        super();
    }

    @Override
    public List<String> select(Double numberThreshold) {

        try {
            String sql = "SELECT table1.word FROM table1 JOIN table2 ON table1.id = table2.foreign_id WHERE " +
                    "table2.number > ? ORDER BY word";
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
