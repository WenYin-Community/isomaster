/*
 * test_iso_operations.vala
 * Regression test for the owned-delegate double-transfer bug:
 * passing owned delegates from a wrapper method into IsoOperations.run
 * without (owned) made valac release the closures right after the call,
 * so the worker thread crashed with SIGSEGV (use-after-free) as soon as
 * it invoked the worker closure (observed when loading an ISO image).
 */

public class TestRunner : Object {
    private IsoOperations ops;

    public TestRunner() {
        ops = new IsoOperations();
    }

    // Mirrors IsoMaster.run_bk_operation: owned delegates re-passed to
    // IsoOperations.run. Ownership MUST be transferred with (owned).
    private void run_bk_operation(string text,
                                  owned IsoOperations.WorkerFunc worker,
                                  owned IsoOperations.DoneFunc on_done) {
        ops.run((owned) worker, (owned) on_done);
    }

    public int go() {
        int result = 0;
        run_bk_operation("test", () => {
            // Sleep so the main thread has returned from run_bk_operation
            // before the worker runs (the bug released the closures there)
            Thread.usleep(100000);
            result = 42;
        }, () => {
            // Runs via Idle on the main loop; not executed here, that's fine
        });

        // Wait for the worker thread to finish; iterate the main context
        // so the completion Idle callback (which clears "running") runs
        for (int i = 0; i < 200 && ops.running; i++) {
            var ctx = MainContext.default();
            while (ctx.pending()) {
                ctx.iteration(false);
            }
            Thread.usleep(10000);
        }

        if (ops.running) {
            stderr.printf("FAIL: worker thread did not finish\n");
            ops.cancel_and_join();
            return 1;
        }
        if (result != 42) {
            stderr.printf("FAIL: worker closure lost/corrupted (result=%d)\n", result);
            return 1;
        }
        return 0;
    }
}

public static int main() {
    var runner = new TestRunner();
    int rc = runner.go();
    stdout.printf(rc == 0 ? "PASS\n" : "FAIL\n");
    return rc;
}
