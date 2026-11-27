import tk.zwander.lockscreenwidgets.lab.LabDragState;

public final class LabDragStateTest {
    private static void check(boolean b) { if (!b) throw new AssertionError(); }
    public static void main(String[] args) {
        LabDragState drag = new LabDragState(8);
        drag.down(100, 150);
        check(drag.move(102, 151, 1) == LabDragState.Result.WAIT);
        check(drag.activate() == LabDragState.Result.START);
        check(drag.move(131, 163, 1) == LabDragState.Result.MOVE);
        check(drag.deltaX() == 31 && drag.deltaY() == 13);
        check(drag.up() == LabDragState.Result.DROP);
        check(drag.up() == LabDragState.Result.CANCEL);
        drag.down(0, 0);
        check(drag.move(9, 0, 1) == LabDragState.Result.CANCEL);
        check(drag.activate() == LabDragState.Result.CANCEL);
        drag.down(0, 0);
        check(drag.up() == LabDragState.Result.CANCEL);
        drag.down(0, 0);
        check(drag.activate() == LabDragState.Result.START);
        check(drag.move(5, 0, 2) == LabDragState.Result.CANCEL);
        check(drag.up() == LabDragState.Result.CANCEL);
        drag.down(0, 0);
        check(drag.activate() == LabDragState.Result.START);
        check(drag.cancel() == LabDragState.Result.CANCEL);
        check(drag.up() == LabDragState.Result.CANCEL);
    }
}
