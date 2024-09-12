public class AvoidUpdates {

    private static Boolean hasRun = false;

    public static Boolean runOnce() {
        if (!hasRun) {
            hasRun = true;
            return true;
        }
        return false;
    }

}