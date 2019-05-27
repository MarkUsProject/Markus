public class ExceptionInsert extends Submission {

    public ExceptionInsert() throws ClassNotFoundException {

        super();
    }

    public boolean insert(String newWord) {

        throw new NullPointerException("Get this unchecked exception");
    }

}
