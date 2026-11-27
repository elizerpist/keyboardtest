package tk.zwander.common.activities.add;

public final class WidgetConsentResult {
    public interface Actions {
        void accept(int id);
        void deletePending(int id);
    }
    private WidgetConsentResult() {}
    public static void handle(int pending, int returned, boolean success, boolean matches, Actions actions) {
        if (pending < 0) return;
        if (success && returned == pending && matches) actions.accept(pending);
        else actions.deletePending(pending);
    }
}
