import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;
import static org.junit.jupiter.api.Assertions.fail;

public class Test2 {

    Submission submission = new Submission();

    @Test
    @DisplayName("This test should timeout")
    public void testLoops() {
        assertTimeoutPreemptively(Duration.ofSeconds(10), () -> {
            Thread t = new Thread(() -> {
                submission.loop();
            });
            t.start();
            try {
                t.join();
            }
            catch (InterruptedException e) {
                t.stop();
            }
        });
    }

    @Test
    @DisplayName("This test should fail and print json")
    public void testFailsAndOutputsJson() {
        fail(submission.returnJson());
    }

}
