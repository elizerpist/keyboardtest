import tk.zwander.common.activities.add.WidgetConsentResult;

public final class WidgetConsentResultTest {
    private static final class Recorder implements WidgetConsentResult.Actions {
        int accepted = -1;
        int deleted = -1;
        public void accept(int id) { accepted = id; }
        public void deletePending(int id) { deleted = id; }
    }
    private static void check(boolean value) {
        if (!value) throw new AssertionError();
    }
    public static void main(String[] args) {
        Recorder ok = new Recorder();
        WidgetConsentResult.handle(41, 41, true, true, ok);
        check(ok.accepted == 41 && ok.deleted == -1);
        Recorder denied = new Recorder();
        WidgetConsentResult.handle(41, 41, false, false, denied);
        check(denied.accepted == -1 && denied.deleted == 41);
        Recorder wrong = new Recorder();
        WidgetConsentResult.handle(41, 99, true, true, wrong);
        check(wrong.accepted == -1 && wrong.deleted == 41 && wrong.deleted != 99);
        Recorder stale = new Recorder();
        WidgetConsentResult.handle(-1, 99, true, true, stale);
        check(stale.accepted == -1 && stale.deleted == -1);
        Recorder missing = new Recorder();
        WidgetConsentResult.handle(41, 41, true, false, missing);
        check(missing.accepted == -1 && missing.deleted == 41);
    }
}
