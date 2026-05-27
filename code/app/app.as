#include "../hono/hono.as"

namespace ShadowNine {
    const string HOME_PAGE =
        "<main>"
        "<h1>Hono AS v4</h1>"
        "<p>Session counter <code>{counter}</code></p>"
        "<p>Query message <code>{message}</code></p>"
        "<p>Demo cookie <code>{cookie}</code></p>"
        "<form method=\"get\" action=\"/\">"
        "<label>Message <input name=\"message\" value=\"Hello\"></label>"
        "<button type=\"submit\">Submit query</button>"
        "</form>"
        "<p><a href=\"/?cookie=set\">Set cookie</a> <a href=\"/?cookie=delete\">Delete cookie</a></p>"
        "<p><a href=\"/hello/Strata?greeting=Hi\">Route params</a></p>"
        "</main>";

    HonoResponse@ Home(HonoContext@ c) {
        HonoSession@ session = c.get("session");
        int counter = 0;

        if (session !is null) {
            counter = session.getInt("counter") + 1;
            session.set("counter", counter);
        }

        string message = c.query("message");
        if (message.empty()) {
            message = "not submitted";
        }

        string cookieAction = c.query("cookie");
        if (cookieAction == "set") {
            HonoCookieOptions options;
            options.path = "/";
            options.sameSite = "Lax";
            c.setCookie("demo", "fresh", @options);
        } else if (cookieAction == "delete") {
            c.deleteCookie("demo");
        }

        c.header("X-Example-Header", "HelloFromApp");

        string cookieValue = c.cookie("demo");
        if (cookieValue.empty()) {
            cookieValue = "not set";
        }

        string body = HOME_PAGE.replace("{counter}", string(counter));
        body = body.replace("{message}", EscapeHtml(message));
        body = body.replace("{cookie}", EscapeHtml(cookieValue));
        return c.html(Page("Hono AS v4", body));
    }

    HonoResponse@ PoweredBy(HonoContext@ c) {
        c.header("X-Powered-By", "HonoAngelScript");
        return null;
    }

    HonoResponse@ Hello(HonoContext@ c) {
        string name = c.param("name");
        string greeting = c.query("greeting");

        if (greeting.empty()) {
            greeting = "Hello";
        }

        c.header("X-Route-Param", name);
        return c.text(greeting + ", " + name + "!");
    }

    class HonoApp {
        Hono app;

        HonoApp() {
            app.server("ShadowNineWebServer");
            app.use(@HonoSessions::memory);
            app.use(@PoweredBy);
            app.get("/", @Home);
            app.get("/hello/:name", @Hello);
        }
    }

    HonoApp hono;

    Hono@ App() {
        return @hono.app;
    }

    string EscapeHtml(const string&in value) {
        string escaped = value;
        escaped = escaped.replace("&", "&amp;");
        escaped = escaped.replace("<", "&lt;");
        escaped = escaped.replace(">", "&gt;");
        escaped = escaped.replace("\"", "&quot;");
        escaped = escaped.replace("'", "&#39;");
        return escaped;
    }

    string Page(const string&in title, const string&in body) {
        return
            "<!doctype html>"
            "<html lang=\"en\">"
            "<head>"
            "<meta charset=\"utf-8\">"
            "<link rel=\"icon\" href=\"data:,\">"
            "<title>" + EscapeHtml(title) + "</title>"
            "<style>"
            "body{margin:0;padding:24px;background:#0d1117;color:#eef2f7;font:15px Arial}"
            "main{max-width:520px;margin:auto;padding:22px;border:1px solid #303842;border-radius:8px;background:#161b22}"
            "h1{margin:0 0 16px;font-size:32px}p{color:#b8c4d0}code{color:#8cc8ff}"
            "form{display:grid;gap:10px}input,button{padding:10px;border-radius:6px}input{background:#0b1117;color:#fff;border:1px solid #334150}button{background:#7ee787;border:0;font-weight:700}a{color:#7ee787}"
            "</style>"
            "</head>"
            "<body>"
            + body +
            "</body>"
            "</html>";
    }
}
