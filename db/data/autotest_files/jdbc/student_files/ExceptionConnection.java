public class ExceptionConnection extends Submission {

    public ExceptionConnection() throws ClassNotFoundException {

        super();
    }

    @Override
    public boolean connectDB(String url, String username, String password) {

        throw new NullPointerException("Get this unchecked exception");
    }

}
