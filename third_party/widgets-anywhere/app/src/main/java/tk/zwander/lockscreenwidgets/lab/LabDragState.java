package tk.zwander.lockscreenwidgets.lab;

public final class LabDragState {
    public enum Result { WAIT, START, MOVE, DROP, CANCEL }
    private final float slopSquared;
    private float startX, startY, deltaX, deltaY;
    private boolean tracking, active;

    public LabDragState(float slop) { slopSquared = slop * slop; }
    public void down(float x, float y) {
        startX = x; startY = y; deltaX = 0; deltaY = 0;
        tracking = true; active = false;
    }
    public Result activate() {
        if (!tracking || active) return Result.CANCEL;
        active = true;
        return Result.START;
    }
    public Result move(float x, float y, int pointers) {
        if (!tracking || pointers != 1) return cancel();
        float dx = x - startX, dy = y - startY;
        if (!active) return dx * dx + dy * dy > slopSquared ? cancel() : Result.WAIT;
        deltaX = dx; deltaY = dy;
        return Result.MOVE;
    }
    public Result up() {
        boolean dropped = tracking && active;
        tracking = false; active = false;
        return dropped ? Result.DROP : Result.CANCEL;
    }
    public Result cancel() {
        tracking = false; active = false;
        return Result.CANCEL;
    }
    public float deltaX() { return deltaX; }
    public float deltaY() { return deltaY; }
}
