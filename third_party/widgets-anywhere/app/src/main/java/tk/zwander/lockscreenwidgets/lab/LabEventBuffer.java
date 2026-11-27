package tk.zwander.lockscreenwidgets.lab;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

public final class LabEventBuffer {
    public static final class Snapshot {
        public final List<String> records;
        public final int dropped;
        private Snapshot(List<String> records, int dropped) {
            this.records = Collections.unmodifiableList(new ArrayList<>(records));
            this.dropped = dropped;
        }
    }
    private final int capacity;
    private final ArrayDeque<String> records = new ArrayDeque<>();
    private int dropped;
    private boolean active;
    private Snapshot frozen = new Snapshot(Collections.emptyList(), 0);

    public LabEventBuffer(int capacity) {
        if (capacity <= 0) throw new IllegalArgumentException("capacity");
        this.capacity = capacity;
    }
    public synchronized void start() {
        records.clear(); dropped = 0; active = true;
    }
    public synchronized void record(String event) {
        if (!active) return;
        Objects.requireNonNull(event);
        if (records.size() == capacity) { records.removeFirst(); dropped++; }
        records.addLast(event);
    }
    public synchronized Snapshot freeze() {
        if (active) {
            active = false;
            frozen = new Snapshot(new ArrayList<>(records), dropped);
        }
        return frozen;
    }
}
