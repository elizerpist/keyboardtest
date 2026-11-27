import tk.zwander.lockscreenwidgets.lab.LabEventBuffer;
public final class LabEventBufferTest {
    private static void check(boolean b) { if (!b) throw new AssertionError(); }
    public static void main(String[] args) {
        LabEventBuffer buffer = new LabEventBuffer(2);
        buffer.start(); buffer.record("1"); buffer.record("2"); buffer.record("3");
        LabEventBuffer.Snapshot frozen = buffer.freeze();
        check(frozen.dropped == 1 && frozen.records.size() == 2);
        check(frozen.records.get(0).equals("2") && frozen.records.get(1).equals("3"));
        buffer.record("4");
        check(buffer.freeze().records.equals(frozen.records));
        boolean immutable = false;
        try { frozen.records.add("5"); } catch (UnsupportedOperationException e) { immutable = true; }
        check(immutable);
        buffer.start(); buffer.record("new");
        check(buffer.freeze().records.size() == 1 && frozen.records.size() == 2);
    }
}
