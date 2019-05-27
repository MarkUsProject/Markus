import java.util.List;

public class ExceptionSelect extends Submission {

    public ExceptionSelect() throws ClassNotFoundException {

        super();
    }

    public List<String> select(Double numberThreshold) {

        throw new NullPointerException("Get this unchecked exception");
    }

}
