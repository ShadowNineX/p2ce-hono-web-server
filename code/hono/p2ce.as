#include "../app/app.as"

namespace HonoP2CE {
    Hono@ boundApp;
    string cookieHeader = "";
    bool didLogReady = false;
    const string DEFAULT_BRIDGE_URL = "http://localhost:8080";

    void bind(Hono@ app) {
        @boundApp = app;
    }

    void init() {
        init(DEFAULT_BRIDGE_URL);
    }

    void init(const string&in bridgeUrl) {
        if (didLogReady) {
            return;
        }

        didLogReady = true;

        Msg("[HonoAS] ShadowNine web app ready.\n");
        Msg("[HonoAS] Bridge URL: " + bridgeUrl + "\n");
        Msg("[HonoAS] P2CE receives HTTP through server console commands; the external bridge owns the socket.\n");
        Msg("[HonoAS] Routes: GET /, GET /hello/:name\n");
    }

    void request(const string&in method, const CommandArgs@ args) {
        disableConsoleLogDecoration();

        if (!didLogReady) {
            init(DEFAULT_BRIDGE_URL);
        }

        string path = requestPath(method, args);
        if (path.empty() || path.substr(0, 1) != "/") {
            path = "/";
        }

        bool unsafeQuery = path.locate("&") != uint(-1);
        path = safeRequestPath(path);
        string routePath = withoutQuery(path);
        string queryString = queryOf(path);

        if (boundApp is null) {
            bind(ShadowNine::App());
        }

        if (boundApp is null) {
            HonoContext@ context = HonoContext("GET", routePath);
            HonoResponse@ errorResponse = context.serverError("Application was not initialized.\n");
            applyBridgeHeaders(errorResponse);
            Msg(HonoHttp::toHttp(errorResponse));
            return;
        }

        HonoResponse@ response;
        if (unsafeQuery) {
            @response = badRequest("Multiple query params are not supported by this P2CE console bridge.\n");
        } else if (shouldRespond(routePath)) {
            @response = boundApp.fetch(method, routePath, cookieHeader, queryString);
        } else {
            HonoContext@ context = HonoContext(method, routePath);
            @response = context.noContent();
        }

        applyBridgeHeaders(response);

        if (response.body.length() > 1200) {
            HonoContext@ context = HonoContext("GET", routePath);
            @response = context.serverError("Response body is too large for the P2CE console bridge.\n");
            applyBridgeHeaders(response);
        }

        Msg(HonoHttp::toHttp(response));
    }

    void request(const CommandArgs@ args) {
        request("GET", args);
    }

    void header(const CommandArgs@ args) {
        cookieHeader = headerValue(args.GetCommandString());
    }

    void ignore(const CommandArgs@ args) {
    }

    HonoResponse@ badRequest(const string&in message) {
        HonoResponse@ response = HonoResponse(400, "Bad Request", "text/plain; charset=utf-8", message);
        response.serverName = "ShadowNineWebServer";
        return response;
    }

    bool shouldRespond(const string&in rawPath) {
        string path = rawPath;
        uint queryStart = path.locate("?");
        if (queryStart != uint(-1)) {
            path = path.substr(0, int(queryStart));
        }

        if (path == "/" || path.empty()) {
            return true;
        }

        if (path.length() >= 7 && path.substr(0, 7) == "/hello/") {
            return true;
        }

        return false;
    }

    void applyBridgeHeaders(HonoResponse@ response) {
        response.setHeader("X-Bridge-Version", "p2ce-console-v4");
        response.setHeader("Permissions-Policy", "ch-ua=(), ch-ua-mobile=(), ch-ua-platform=()");
        response.setHeader("Cache-Control", "no-store");
    }

    string requestPath(const string&in method, const CommandArgs@ args) {
        string path = "/";

        string command = args.GetCommandString();
        uint firstSpace = command.locate(" ");
        if (firstSpace == uint(-1)) {
            return path;
        }

        string firstToken = command.substr(0, int(firstSpace));
        string rest = command.substr(int(firstSpace + 1)).trim();
        if (rest.empty()) {
            return path;
        }

        uint secondSpace = rest.locate(" ");
        if (secondSpace != uint(-1)) {
            path = rest.substr(0, int(secondSpace));
        } else {
            path = rest;
        }

        if (firstToken != method && firstToken.length() > 0 && firstToken.substr(0, 1) == "/") {
            path = firstToken;
        }

        return path;
    }

    string safeRequestPath(const string&in rawPath) {
        string path = rawPath;

        if (path.length() > 160) {
            path = path.substr(0, 160);
        }

        uint extraQuery = path.locate("&");
        if (extraQuery != uint(-1)) {
            path = path.substr(0, int(extraQuery));
        }

        return path;
    }

    string withoutQuery(const string&in rawPath) {
        uint queryStart = rawPath.locate("?");
        if (queryStart == uint(-1)) {
            return rawPath;
        }

        if (queryStart == 0) {
            return "/";
        }

        return rawPath.substr(0, int(queryStart));
    }

    string queryOf(const string&in rawPath) {
        uint queryStart = rawPath.locate("?");
        if (queryStart == uint(-1)) {
            return "";
        }

        string queryString = rawPath.substr(int(queryStart + 1));
        if (queryString.length() > 128) {
            queryString = queryString.substr(0, 128);
        }

        return queryString;
    }

    string headerValue(const string&in command) {
        uint separator = command.locate(":");
        if (separator != uint(-1)) {
            return command.substr(int(separator + 1)).trim();
        }

        uint firstSpace = command.locate(" ");
        if (firstSpace != uint(-1)) {
            return command.substr(int(firstSpace + 1)).trim();
        }

        return "";
    }

    void disableConsoleLogDecoration() {
        configureConsoleFiltering();

        ConVarRef channelMode("con_log_channel_mode");
        if (channelMode.IsValid()) {
            channelMode.SetValue(0);
        }

        ConVarRef severityMode("con_log_severity_mode");
        if (severityMode.IsValid()) {
            severityMode.SetValue(0);
        }

        ConVarRef timestamp("con_timestamp");
        if (timestamp.IsValid()) {
            timestamp.SetValue(0);
        }
    }

    void configureConsoleFiltering() {
        ConVarRef filterEnable("con_filter_enable");
        if (filterEnable.IsValid()) {
            filterEnable.SetValue(1);
        }

        ConVarRef filterText("con_filter_text");
        if (filterText.IsValid()) {
            filterText.SetValue("");
        }

        ConVarRef filterTextOut("con_filter_text_out");
        if (filterTextOut.IsValid()) {
            filterTextOut.SetValue("Unknown command");
        }
    }
}
