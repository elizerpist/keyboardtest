import tk.zwander.lockscreenwidgets.lab.LabFrameBounds;
public final class LabFrameBoundsTest {
    private static void check(boolean b) { if (!b) throw new AssertionError(); }
    public static void main(String[] args) {
        check(LabFrameBounds.clamp(-1000, 1000, 200, 30, 70) == -370);
        check(LabFrameBounds.clamp(1000, 1000, 200, 30, 70) == 330);
        check(LabFrameBounds.clamp(5, 1000, 200, 30, 70) == 5);
        check(LabFrameBounds.clamp(0, 100, 120, 10, 20) == -5);
    }
}
