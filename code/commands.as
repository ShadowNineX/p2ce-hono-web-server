#if SERVER
#include "hono/p2ce.as"

[ServerCommand("GET", "HTTP")]
void ShadowNineHttpGetCommand(const CommandArgs@ args) { HonoP2CE::request("GET", args); }

[ServerCommand("HEAD", "HTTP")]
void ShadowNineHttpHeadCommand(const CommandArgs@ args) { HonoP2CE::request("HEAD", args); }

[ServerCommand("POST", "HTTP")]
void ShadowNineHttpPostCommand(const CommandArgs@ args) { HonoP2CE::request("POST", args); }

[ServerCommand("PUT", "HTTP")]
void ShadowNineHttpPutCommand(const CommandArgs@ args) { HonoP2CE::request("PUT", args); }

[ServerCommand("PATCH", "HTTP")]
void ShadowNineHttpPatchCommand(const CommandArgs@ args) { HonoP2CE::request("PATCH", args); }

[ServerCommand("DELETE", "HTTP")]
void ShadowNineHttpDeleteCommand(const CommandArgs@ args) { HonoP2CE::request("DELETE", args); }

[ServerCommand("OPTIONS", "HTTP")]
void ShadowNineHttpOptionsCommand(const CommandArgs@ args) { HonoP2CE::request("OPTIONS", args); }

[ServerCommand("Cookie:", "HTTP")]
void ShadowNineHttpCookieHeaderCommand(const CommandArgs@ args) { HonoP2CE::header(args); }

[ServerCommand("Cookie", "HTTP")]
void ShadowNineHttpCookieHeaderNoColonCommand(const CommandArgs@ args) { HonoP2CE::header(args); }

class ShadowNineHttpAutoInit {
    ShadowNineHttpAutoInit() {
        HonoP2CE::init("http://localhost:8080");
    }
}

ShadowNineHttpAutoInit g_shadowNineHttpAutoInit;
#endif
