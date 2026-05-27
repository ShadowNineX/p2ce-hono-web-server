#include "crypto.as"

funcdef HonoResponse@ HonoHandler(HonoContext@ c);
funcdef HonoResponse@ HonoMiddleware(HonoContext@ c);

class HonoHeader {
    string name;
    string value;

    HonoHeader(const string&in name, const string&in value) {
        this.name = name;
        this.value = value;
    }
}

class HonoCookie {
    string name;
    string value;

    HonoCookie(const string&in name, const string&in value) {
        this.name = name;
        this.value = value;
    }
}

class HonoCookieOptions {
    string path;
    string domain;
    string maxAge;
    string expires;
    string sameSite;
    bool httpOnly;
    bool secure;

    HonoCookieOptions() {
        path = "/";
        domain = "";
        maxAge = "";
        expires = "";
        sameSite = "";
        httpOnly = false;
        secure = false;
    }
}

class HonoParam {
    string name;
    string value;

    HonoParam(const string&in name, const string&in value) {
        this.name = name;
        this.value = value;
    }
}

class HonoVariable {
    string name;
    string value;

    HonoVariable(const string&in name, const string&in value) {
        this.name = name;
        this.value = value;
    }
}

class HonoSessionEntry {
    string name;
    string value;

    HonoSessionEntry(const string&in name, const string&in value) {
        this.name = name;
        this.value = value;
    }
}

class HonoSession {
    array<HonoSessionEntry@> entries;
    bool dirty;

    HonoSession() {
        dirty = false;
    }

    bool has(const string&in name) {
        return indexOf(name) >= 0;
    }

    string get(const string&in name) {
        int index = indexOf(name);
        if (index < 0) {
            return "";
        }

        return entries[index].value;
    }

    int getInt(const string&in name) {
        string value = get(name);
        if (value.empty()) {
            return 0;
        }

        return int(value.toInt());
    }

    void set(const string&in name, const string&in value) {
        int index = indexOf(name);
        if (index >= 0) {
            entries[index].value = value;
            dirty = true;
            return;
        }

        HonoSessionEntry@ entry = HonoSessionEntry(name, value);
        entries.insertLast(entry);
        dirty = true;
    }

    void set(const string&in name, int value) {
        set(name, string(value));
    }

    void remove(const string&in name) {
        int index = indexOf(name);
        if (index >= 0) {
            entries.removeAt(uint(index));
            dirty = true;
        }
    }

    void clear() {
        entries.resize(0);
        dirty = true;
    }

    void load(const string&in value) {
        entries.resize(0);

        if (value.empty()) {
            dirty = false;
            return;
        }

        array<string>@ pairs = value.split("&");
        for (uint i = 0; i < pairs.length(); i++) {
            string pair = pairs[i];
            uint separator = pair.locate("=");

            if (separator == uint(-1)) {
                continue;
            }

            string name = HonoUrl::decode(pair.substr(0, int(separator)));
            string entryValue = HonoUrl::decode(pair.substr(int(separator + 1)));

            HonoSessionEntry@ entry = HonoSessionEntry(name, entryValue);
            entries.insertLast(entry);
        }

        dirty = false;
    }

    string dump() {
        string value = "";

        for (uint i = 0; i < entries.length(); i++) {
            if (i > 0) {
                value += "&";
            }

            value += HonoUrl::encode(entries[i].name) + "=" + HonoUrl::encode(entries[i].value);
        }

        return value;
    }

    int indexOf(const string&in name) {
        for (uint i = 0; i < entries.length(); i++) {
            if (entries[i].name == name) {
                return int(i);
            }
        }

        return -1;
    }
}

class HonoSessionStoreEntry {
    string id;
    HonoSession@ session;

    HonoSessionStoreEntry(const string&in id, HonoSession@ session) {
        this.id = id;
        @this.session = session;
    }
}

class HonoResponse {
    int status;
    string statusText;
    string contentType;
    string body;
    string serverName;
    array<HonoHeader@> headers;

    HonoResponse(int status, const string&in statusText, const string&in contentType, const string&in body) {
        this.status = status;
        this.statusText = statusText;
        this.contentType = contentType;
        this.body = body;
        this.serverName = "HonoAngelScript";
    }

    void setHeader(const string&in name, const string&in value) {
        for (uint i = 0; i < headers.length(); i++) {
            if (headers[i].name == name) {
                headers[i].value = value;
                return;
            }
        }

        HonoHeader@ header = HonoHeader(name, value);
        headers.insertLast(header);
    }

    void appendHeader(const string&in name, const string&in value) {
        HonoHeader@ header = HonoHeader(name, value);
        headers.insertLast(header);
    }
}

class HonoContext {
    string method;
    string path;
    string queryString;
    string cookieHeader;
    int responseStatus;
    string responseStatusText;
    array<HonoHeader@> headers;
    array<HonoCookie@> cookies;
    array<HonoParam@> params;
    array<HonoVariable@> variables;
    HonoSession@ session;
    string sessionCookieName;
    string sessionId;
    bool sessionIsNew;

    HonoContext(const string&in method, const string&in rawPath) {
        this.method = method;
        this.responseStatus = 200;
        this.responseStatusText = "OK";
        this.sessionCookieName = "";
        this.sessionId = "";
        this.sessionIsNew = false;

        uint queryStart = rawPath.locate("?");
        if (queryStart == uint(-1)) {
            this.path = rawPath;
            this.queryString = "";
        } else {
            this.path = rawPath.substr(0, int(queryStart));
            this.queryString = rawPath.substr(int(queryStart + 1));
            if (this.queryString.length() > 128) {
                this.queryString = this.queryString.substr(0, 128);
            }
        }

        if (this.path.empty()) {
            this.path = "/";
        }
    }

    void setQueryString(const string&in value) {
        queryString = value;
        if (queryString.length() > 128) {
            queryString = queryString.substr(0, 128);
        }
    }

    void status(int code) {
        responseStatus = code;
        responseStatusText = HonoStatus::text(code);
    }

    void header(const string&in name, const string&in value) {
        for (uint i = 0; i < headers.length(); i++) {
            if (headers[i].name == name) {
                headers[i].value = value;
                return;
            }
        }

        HonoHeader@ header = HonoHeader(name, value);
        headers.insertLast(header);
    }

    void appendHeader(const string&in name, const string&in value) {
        HonoHeader@ header = HonoHeader(name, value);
        headers.insertLast(header);
    }

    void setCookieHeader(const string&in value) {
        cookieHeader = value;
        cookies.resize(0);
        HonoCookies::parse(cookieHeader, cookies);
    }

    string cookie(const string&in name) {
        return HonoCookies::getCookie(this, name);
    }

    void setCookie(const string&in name, const string&in value) {
        HonoCookies::setCookie(this, name, value);
    }

    void setCookie(const string&in name, const string&in value, HonoCookieOptions@ options) {
        HonoCookies::setCookie(this, name, value, options);
    }

    void deleteCookie(const string&in name) {
        HonoCookies::deleteCookie(this, name);
    }

    string param(const string&in name) {
        for (uint i = 0; i < params.length(); i++) {
            if (params[i].name == name) {
                return params[i].value;
            }
        }

        return "";
    }

    string query(const string&in name) {
        string remaining = queryString;

        for (int i = 0; i < 16 && !remaining.empty(); i++) {
            string pair;
            uint amp = remaining.locate("&");

            if (amp == uint(-1)) {
                pair = remaining;
                remaining = "";
            } else {
                pair = remaining.substr(0, int(amp));
                remaining = remaining.substr(int(amp + 1));
            }

            uint separator = pair.locate("=");
            string key;
            string value;

            if (separator == uint(-1)) {
                key = pair;
                value = "";
            } else {
                key = pair.substr(0, int(separator));
                value = pair.substr(int(separator + 1));
            }

            if (HonoUrl::decode(key) == name) {
                return HonoUrl::decode(value);
            }
        }

        return "";
    }

    void set(const string&in name, const string&in value) {
        for (uint i = 0; i < variables.length(); i++) {
            if (variables[i].name == name) {
                variables[i].value = value;
                return;
            }
        }

        HonoVariable@ variable = HonoVariable(name, value);
        variables.insertLast(variable);
    }

    void set(const string&in name, HonoSession@ value) {
        if (name == "session") {
            @session = value;
        }
    }

    string getVar(const string&in name) {
        for (uint i = 0; i < variables.length(); i++) {
            if (variables[i].name == name) {
                return variables[i].value;
            }
        }

        return "";
    }

    HonoSession@ get(const string&in name) {
        if (name == "session") {
            return session;
        }

        return null;
    }

    HonoResponse@ text(const string&in body) {
        return response("text/plain; charset=utf-8", body);
    }

    HonoResponse@ text(const string&in body, int statusCode) {
        status(statusCode);
        return text(body);
    }

    HonoResponse@ html(const string&in body) {
        return response("text/html; charset=utf-8", body);
    }

    HonoResponse@ html(const string&in body, int statusCode) {
        status(statusCode);
        return html(body);
    }

    HonoResponse@ json(const string&in body) {
        return response("application/json; charset=utf-8", body);
    }

    HonoResponse@ json(const string&in body, int statusCode) {
        status(statusCode);
        return json(body);
    }

    HonoResponse@ redirect(const string&in location) {
        return redirect(location, 302);
    }

    HonoResponse@ redirect(const string&in location, int statusCode) {
        status(statusCode);
        header("Location", location);
        return response("", "");
    }

    HonoResponse@ notFound() {
        status(404);
        return text("Not Found\n");
    }

    HonoResponse@ noContent() {
        status(204);
        return response("", "");
    }

    HonoResponse@ serverError(const string&in body) {
        status(500);
        return text(body);
    }

    HonoResponse@ response(const string&in contentType, const string&in body) {
        return withHeaders(HonoResponse(responseStatus, responseStatusText, contentType, body));
    }

    HonoResponse@ withHeaders(HonoResponse@ response) {
        for (uint i = 0; i < headers.length(); i++) {
            if (headers[i].name == "Set-Cookie") {
                response.appendHeader(headers[i].name, headers[i].value);
            } else {
                response.setHeader(headers[i].name, headers[i].value);
            }
        }

        return response;
    }
}

namespace HonoStatus {
    string text(int status) {
        if (status == 200) return "OK";
        if (status == 201) return "Created";
        if (status == 202) return "Accepted";
        if (status == 204) return "No Content";
        if (status == 301) return "Moved Permanently";
        if (status == 302) return "Found";
        if (status == 304) return "Not Modified";
        if (status == 400) return "Bad Request";
        if (status == 401) return "Unauthorized";
        if (status == 403) return "Forbidden";
        if (status == 404) return "Not Found";
        if (status == 405) return "Method Not Allowed";
        if (status == 500) return "Internal Server Error";
        if (status == 502) return "Bad Gateway";
        if (status == 503) return "Service Unavailable";

        return "OK";
    }
}

namespace HonoUrl {
    string encode(const string&in value) {
        string encoded = value;
        encoded = encoded.replace("%", "%25");
        encoded = encoded.replace(" ", "%20");
        encoded = encoded.replace("!", "%21");
        encoded = encoded.replace("\"", "%22");
        encoded = encoded.replace("#", "%23");
        encoded = encoded.replace("$", "%24");
        encoded = encoded.replace("&", "%26");
        encoded = encoded.replace("'", "%27");
        encoded = encoded.replace("(", "%28");
        encoded = encoded.replace(")", "%29");
        encoded = encoded.replace("+", "%2B");
        encoded = encoded.replace(",", "%2C");
        encoded = encoded.replace("/", "%2F");
        encoded = encoded.replace(":", "%3A");
        encoded = encoded.replace(";", "%3B");
        encoded = encoded.replace("=", "%3D");
        encoded = encoded.replace("?", "%3F");
        encoded = encoded.replace("@", "%40");
        return encoded;
    }

    string decode(const string&in value) {
        if (value.locate("+") == uint(-1) && value.locate("%") == uint(-1)) {
            return value;
        }

        string decoded = value;
        decoded = decoded.replace("+", " ");
        decoded = replaceEscape(decoded, "%20", " ");
        decoded = replaceEscape(decoded, "%21", "!");
        decoded = replaceEscape(decoded, "%22", "\"");
        decoded = replaceEscape(decoded, "%23", "#");
        decoded = replaceEscape(decoded, "%24", "$");
        decoded = replaceEscape(decoded, "%25", "%");
        decoded = replaceEscape(decoded, "%26", "&");
        decoded = replaceEscape(decoded, "%27", "'");
        decoded = replaceEscape(decoded, "%28", "(");
        decoded = replaceEscape(decoded, "%29", ")");
        decoded = replaceEscape(decoded, "%2B", "+");
        decoded = replaceEscape(decoded, "%2C", ",");
        decoded = replaceEscape(decoded, "%2D", "-");
        decoded = replaceEscape(decoded, "%2E", ".");
        decoded = replaceEscape(decoded, "%2F", "/");
        decoded = replaceEscape(decoded, "%3A", ":");
        decoded = replaceEscape(decoded, "%3B", ";");
        decoded = replaceEscape(decoded, "%3D", "=");
        decoded = replaceEscape(decoded, "%3F", "?");
        decoded = replaceEscape(decoded, "%40", "@");
        return decoded;
    }

    string replaceEscape(const string&in value, const string&in encoded, const string&in replacement) {
        string decoded = value.replace(encoded, replacement);
        return decoded.replace(encoded.tolower(), replacement);
    }
}

namespace HonoCookies {
    void parse(const string&in header, array<HonoCookie@>&inout cookies) {
        array<string>@ pairs = header.split(";");

        for (uint i = 0; i < pairs.length(); i++) {
            string pair = pairs[i].trim();
            uint separator = pair.locate("=");

            if (separator == uint(-1)) {
                continue;
            }

            string name = pair.substr(0, int(separator)).trim();
            string value = pair.substr(int(separator + 1)).trim();
            HonoCookie@ cookie = HonoCookie(name, HonoUrl::decode(value));
            cookies.insertLast(cookie);
        }
    }

    string getCookie(HonoContext@ c, const string&in name) {
        for (uint i = 0; i < c.cookies.length(); i++) {
            if (c.cookies[i].name == name) {
                return c.cookies[i].value;
            }
        }

        return "";
    }

    void setCookie(HonoContext@ c, const string&in name, const string&in value) {
        HonoCookieOptions options;
        setCookie(c, name, value, @options);
    }

    void setCookie(HonoContext@ c, const string&in name, const string&in value, HonoCookieOptions@ options) {
        c.appendHeader("Set-Cookie", serialize(name, value, options));
    }

    void deleteCookie(HonoContext@ c, const string&in name) {
        HonoCookieOptions options;
        options.maxAge = "0";
        c.appendHeader("Set-Cookie", serialize(name, "", @options));
    }

    string serialize(const string&in name, const string&in value, HonoCookieOptions@ options) {
        string cookie = name + "=" + HonoUrl::encode(value);

        if (!options.path.empty()) {
            cookie += "; Path=" + options.path;
        }

        if (!options.domain.empty()) {
            cookie += "; Domain=" + options.domain;
        }

        if (!options.maxAge.empty()) {
            cookie += "; Max-Age=" + options.maxAge;
        }

        if (!options.expires.empty()) {
            cookie += "; Expires=" + options.expires;
        }

        if (!options.sameSite.empty()) {
            cookie += "; SameSite=" + options.sameSite;
        }

        if (options.httpOnly) {
            cookie += "; HttpOnly";
        }

        if (options.secure) {
            cookie += "; Secure";
        }

        return cookie;
    }
}

namespace HonoSessions {
    const string DEFAULT_COOKIE_NAME = "hono_session";
    HonoSession memorySession;
    array<HonoSessionStoreEntry@> cookieStore;

    HonoResponse@ memory(HonoContext@ c) {
        c.set("session", @memorySession);
        return null;
    }

    HonoResponse@ cookie(HonoContext@ c) {
        string sid = c.cookie(DEFAULT_COOKIE_NAME);
        HonoSession@ session;

        if (HonoCrypto::isSessionId(sid)) {
            @session = getSession(sid);
        }

        if (session is null) {
            sid = makeUniqueSessionId();
            @session = HonoSession();
            HonoSessionStoreEntry@ entry = HonoSessionStoreEntry(sid, session);
            cookieStore.insertLast(entry);
            c.sessionIsNew = true;
        }

        c.sessionCookieName = DEFAULT_COOKIE_NAME;
        c.sessionId = sid;
        c.set("session", @session);
        return null;
    }

    void commit(HonoContext@ c, HonoResponse@ response) {
        if (c.session is null || c.sessionCookieName.empty() || c.sessionId.empty()) {
            return;
        }

        if (!c.sessionIsNew && !c.session.dirty) {
            return;
        }

        HonoCookieOptions options;
        options.httpOnly = true;
        options.sameSite = "Lax";
        response.appendHeader("Set-Cookie", HonoCookies::serialize(c.sessionCookieName, c.sessionId, @options));
        c.session.dirty = false;
        c.sessionIsNew = false;
    }

    HonoSession@ getSession(const string&in sid) {
        for (uint i = 0; i < cookieStore.length(); i++) {
            if (cookieStore[i].id == sid) {
                return cookieStore[i].session;
            }
        }

        return null;
    }

    string makeUniqueSessionId() {
        string sid = HonoCrypto::makeSessionId();

        for (int i = 0; i < 8 && getSession(sid) !is null; i++) {
            sid = HonoCrypto::makeSessionId();
        }

        return sid;
    }
}

class HonoRoute {
    string method;
    string path;
    HonoHandler@ handler;

    HonoRoute(const string&in method, const string&in path, HonoHandler@ handler) {
        this.method = method;
        this.path = path;
        @this.handler = handler;
    }

    bool matches(HonoContext@ context) const {
        if (this.method != "ALL" && this.method != context.method) {
            return false;
        }

        return HonoPath::match(this.path, context.path, context.params);
    }
}

class HonoMiddlewareRoute {
    string method;
    string path;
    HonoMiddleware@ middleware;

    HonoMiddlewareRoute(const string&in method, const string&in path, HonoMiddleware@ middleware) {
        this.method = method;
        this.path = path;
        @this.middleware = middleware;
    }

    bool matches(HonoContext@ context) const {
        if (this.method != "ALL" && this.method != context.method) {
            return false;
        }

        array<HonoParam@> ignored;
        return HonoPath::match(this.path, context.path, ignored);
    }
}

class Hono {
    array<HonoRoute@> routes;
    array<HonoMiddlewareRoute@> middlewares;
    string serverName;

    Hono() {
        serverName = "HonoAngelScript";
    }

    void clear() {
        routes.resize(0);
        middlewares.resize(0);
    }

    void server(const string&in name) {
        serverName = name;
    }

    void get(const string&in path, HonoHandler@ handler) {
        add("GET", path, handler);
    }

    void head(const string&in path, HonoHandler@ handler) {
        add("HEAD", path, handler);
    }

    void post(const string&in path, HonoHandler@ handler) {
        add("POST", path, handler);
    }

    void put(const string&in path, HonoHandler@ handler) {
        add("PUT", path, handler);
    }

    void patch(const string&in path, HonoHandler@ handler) {
        add("PATCH", path, handler);
    }

    void del(const string&in path, HonoHandler@ handler) {
        add("DELETE", path, handler);
    }

    void options(const string&in path, HonoHandler@ handler) {
        add("OPTIONS", path, handler);
    }

    void all(const string&in path, HonoHandler@ handler) {
        add("ALL", path, handler);
    }

    void use(HonoMiddleware@ middleware) {
        addMiddleware("ALL", "*", middleware);
    }

    void use(const string&in path, HonoMiddleware@ middleware) {
        addMiddleware("ALL", path, middleware);
    }

    void use(const string&in method, const string&in path, HonoMiddleware@ middleware) {
        addMiddleware(method, path, middleware);
    }

    HonoResponse@ fetch(const string&in method, const string&in path) {
        return fetch(method, path, "");
    }

    HonoResponse@ fetch(const string&in method, const string&in path, const string&in cookieHeader) {
        return fetch(method, path, cookieHeader, "");
    }

    HonoResponse@ fetch(const string&in method, const string&in path, const string&in cookieHeader, const string&in queryString) {
        HonoResponse@ response;
        HonoContext@ context = HonoContext(method, path);
        context.setQueryString(queryString);

        if (!cookieHeader.empty()) {
            context.setCookieHeader(cookieHeader);
        }

        for (uint i = 0; i < middlewares.length(); i++) {
            HonoMiddlewareRoute@ middleware = middlewares[i];
            if (middleware.matches(context)) {
                @response = middleware.middleware(context);
                if (response !is null) {
                    response.serverName = serverName;
                    HonoSessions::commit(context, response);
                    return response;
                }
            }
        }

        for (uint i = 0; i < routes.length(); i++) {
            HonoRoute@ route = routes[i];
            context.params.resize(0);
            if (route.matches(context)) {
                @response = route.handler(context);
                if (response is null) {
                    @response = context.noContent();
                }
                response.serverName = serverName;
                HonoSessions::commit(context, response);
                return response;
            }
        }

        @response = context.notFound();
        response.serverName = serverName;
        HonoSessions::commit(context, response);
        return response;
    }

    void add(const string&in method, const string&in path, HonoHandler@ handler) {
        HonoRoute@ route = HonoRoute(method, path, handler);
        routes.insertLast(route);
    }

    void addMiddleware(const string&in method, const string&in path, HonoMiddleware@ middleware) {
        HonoMiddlewareRoute@ route = HonoMiddlewareRoute(method, path, middleware);
        middlewares.insertLast(route);
    }
}

namespace HonoPath {
    bool match(const string&in pattern, const string&in path, array<HonoParam@>&inout params) {
        if (pattern == "*" || pattern == "/*") {
            return true;
        }

        if (pattern == path) {
            return true;
        }

        array<string>@ patternParts = pattern.split("/");
        array<string>@ pathParts = path.split("/");

        if (patternParts.length() > 0 && patternParts[patternParts.length() - 1] == "*") {
            if (pathParts.length() < patternParts.length() - 1) {
                return false;
            }
        } else if (patternParts.length() != pathParts.length()) {
            return false;
        }

        for (uint i = 0; i < patternParts.length(); i++) {
            string patternPart = patternParts[i];

            if (patternPart == "*") {
                return true;
            }

            if (i >= pathParts.length()) {
                return false;
            }

            string pathPart = pathParts[i];

            if (patternPart.length() > 0 && patternPart.substr(0, 1) == ":") {
                HonoParam@ param = HonoParam(patternPart.substr(1), pathPart);
                params.insertLast(param);
                continue;
            }

            if (patternPart != pathPart) {
                return false;
            }
        }

        return true;
    }
}

namespace HonoHttp {
    string toHttp(HonoResponse@ response) {
        const string NL = "\n";
        string head =
            "HTTP/1.0 " + string(response.status) + " " + response.statusText + NL +
            "Server: " + response.serverName + NL;

        if (response.contentType.length() > 0) {
            head += "Content-Type: " + response.contentType + NL;
        }

        head +=
            headerLines(response) +
            "Content-Length: " + string(response.body.length()) + NL +
            "Connection: close" + NL +
            NL;

        return head + response.body;
    }

    string headerLines(HonoResponse@ response) {
        string lines = "";

        for (uint i = 0; i < response.headers.length(); i++) {
            lines += response.headers[i].name + ": " + response.headers[i].value + "\n";
        }

        return lines;
    }
}
