package tk.zwander.lockscreenwidgets.lab;

public final class LabFrameBounds {
    private LabFrameBounds() {}
    public static int clamp(int offset, int viewport, int frame, int start, int end) {
        long lower = (long) start + frame / 2L - viewport / 2L;
        long upper = (long) viewport - end - (frame - frame / 2L) - viewport / 2L;
        if (lower > upper) return (int) ((lower + upper) / 2L);
        return (int) Math.max(lower, Math.min(upper, offset));
    }
}
