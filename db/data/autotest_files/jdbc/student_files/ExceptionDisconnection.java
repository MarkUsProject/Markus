public class ExceptionDisconnection extends Submission {

    public ExceptionDisconnection() throws ClassNotFoundException {

        super();
    }

    @Override
    public boolean disconnectDB() {

        throw new NullPointerException("Get this unchecked exception");
    }

}
