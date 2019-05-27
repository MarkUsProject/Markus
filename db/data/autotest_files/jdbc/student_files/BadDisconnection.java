public class BadDisconnection extends Submission {

    public BadDisconnection() throws ClassNotFoundException {

        super();
    }

    @Override
    public boolean disconnectDB() {

        return true;
    }

}
