import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class Test1 {

    Submission submission = new Submission();

    @Test
    @DisplayName("This test should pass")
    public void testPasses() {
        assertTrue(submission.returnTrue());
    }

    @Test
    @DisplayName("This test should fail")
    public void testFails() {
        assertTrue(submission.returnFalse());
    }

}
