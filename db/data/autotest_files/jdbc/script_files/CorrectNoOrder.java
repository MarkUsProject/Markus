import java.sql.PreparedStatement;

public class CorrectNoOrder extends Solution {

    public CorrectNoOrder() throws ClassNotFoundException {

        super();
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
