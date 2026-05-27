# AngelScript Context

## Loading

- Local server API reference:
  - `C:\Program Files (x86)\Steam\steamapps\common\Portal 2 Community Edition\p2ce\data\server\api_reference.html`
  - `C:\Program Files (x86)\Steam\steamapps\common\Portal 2 Community Edition\p2ce\data\server\as.predefined`
- VS Code AngelScript LSP needs `.vscode/settings.json` to force-include the P2CE `as.predefined`; otherwise app-provided symbols like `string`, `CommandArgs`, `Msg`, and `Msgl` show as undefined even though the game provides them.
- Place AngelScript files in the addon `code/` folder.
- The engine auto-loads only these entry files when they are directly inside `code/`:
  - `init.as`: loaded by both server and client.
  - `sv_init.as`: loaded only by the server.
  - `cl_init.as`: loaded only by the client.
- AngelScript does not allow top-level function calls. For load-time startup logic, create a global object whose constructor calls the init function.
- Use the in-game `reload` command after editing scripts so the engine recompiles them on the next load/reload pass.
- Use `Msgl(string)` for console logging with a newline, or `Msg(string)` if you want to control newlines manually.
- Current P2CE builds define `SERVER` and `CLIENT` for conditional compilation. Keep domain-specific bindings behind `#if SERVER` or `#if CLIENT`.
- A console-command HTTP bridge must be reachable from the console domain receiving the browser request. Current choice: `GET` is bound as a server command, so a server/map must be active for it to run.
- The local AngelScript dump exposes `Msg(const string&in)` / `Msgl(const string&in)` for printing from script. It does not expose a separate global `print(...)` AngelScript function.
- `Msg`/`Msgl` output through the script log channel, so they can appear with a `[scriptsys]` prefix.
- `point_servercommand` plus `echo ...` is not safe for HTTP headers: `echo` can rewrite `Header: value` as `Header : value`, append spaces, and treat semicolons as command separators.
- The online Strata AngelScript game page and local `as.predefined` expose `Msg`, `Msgl`, `Warning`, `DevMsg`, `ConVarRef`, command args, entities, etc., but no raw socket/HTTP writer.
- `con_log_channel_mode`, `con_log_severity_mode`, and `con_timestamp` are console cvars listed in the Strata command docs. Set them to `0` with `ConVarRef` before printing HTTP so `Msg(...)` has the best chance of reaching the console bridge without `[channel]` or timestamp decoration.
- Browsers may keep the tab spinning even after `curl` succeeds if the console bridge does not actually close the socket or if `/favicon.ico` stays pending. Prefer `HTTP/1.0` responses and return `204 No Content` for `/favicon.ico`.
- VScript/PPMod `ppmod.alias(...)` equivalent in P2CE AngelScript is not a runtime alias function. Use command metadata on a function instead:
  - `[ClientCommand("name", "help text")]` for client-console commands.
  - `[ServerCommand("name", "help text")]` for server-console commands.
- The Strata AngelScript guide's first command example uses `[ClientCommand("HelloWorld", "")] void MyCommand(const CommandArgs@ args) { Msg("Hello world from AngelScript!\n"); }`, confirming command metadata plus `Msg` is the documented command/output pattern.
- HTTP responses need CRLF line endings, a blank line after headers, and a correct `Content-Length`.

## Syntax Notes

- AngelScript is statically typed and C++-like.
- This AngelScript build exposes `string.format(...)`, but keep HTTP response headers static when possible so an unexpected format syntax cannot produce invalid headers.
- Adjacent string literals are concatenated by the compiler, so long templates can be split across lines without `+`.
- Object handles use `@`, for example `const CommandArgs@ args`.
- Interfaces declare a contract:

```angelscript
interface IStartupTask
{
    void Run();
}
```

- Classes implement interfaces with `: InterfaceName`:

```angelscript
class StartupLogTask : IStartupTask
{
    void Run()
    {
        Msgl("Started");
    }
}
```

- Metadata attributes such as `[ServerCommand(...)]` and `[ClientCommand(...)]` are placed immediately before function declarations.
- Server command handlers use `const CommandArgs@ args`; `CommandArgs` exposes `ArgC()`, `Arg(int idx)`, `opIndex(int idx)`, and `GetCommandString()`.



