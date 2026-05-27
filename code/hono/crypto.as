namespace HonoCrypto {
    int sessionCounter = 0;

    string makeSessionId() {
        sessionCounter++;
        return "session-" + string(sessionCounter);
    }

    bool isSessionId(const string&in value) {
        if (value.length() < 9) {
            return false;
        }

        if (value.substr(0, 8) != "session-") {
            return false;
        }

        return true;
    }
}
