/*
 * ISO Master - background operation framework
 *
 * Runs bk operations on a worker thread so the UI stays responsive.
 * Only one operation may run at a time, and the window close path
 * cancels and joins the worker before the C state is freed.
 *
 * This class has no UI or bk dependency: it only manages the thread
 * lifecycle. Progress reporting stays in the application class, which
 * receives the C progress callbacks.
 */

public class IsoOperations : Object {
    // Worker callback: runs on the worker thread (bk calls only)
    public delegate void WorkerFunc();
    // Completion callback: runs on the main loop after the worker exits
    public delegate void DoneFunc();

    public bool running { get; private set; }
    public bool closing { get; set; }

    private GLib.Thread<void>? active_thread = null;

    // Start a worker thread. Returns false if an operation is already
    // running or the app is closing (caller decides how to report it).
    public bool run(owned WorkerFunc worker, owned DoneFunc done) {
        if (closing || running) {
            return false;
        }
        running = true;
        active_thread = new GLib.Thread<void>("bk-operation", () => {
            worker();
            Idle.add(() => {
                running = false;
                if (!closing) {
                    done();
                }
                return Source.REMOVE;
            });
        });
        return true;
    }

    // Cancel a running operation and wait for the worker to finish.
    // Must be called from the main thread while closing.
    public void cancel_and_join() {
        closing = true;
        if (active_thread != null && running) {
            active_thread.join();
            active_thread = null;
        }
    }
}
