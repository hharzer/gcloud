import {createServer, plugins} from "restify";
import {cookieParser} from "util/cookie";
import {sessionParser} from "util/session";
import {formatHtml} from "util/formatter";
import {closeServer} from "util/middleware";
import {addHomeRoute} from "route/home/util/routing";
import {addUserRoute} from "route/user/util/routing";

const serverConfg = {formatters: {"text/html": formatHtml("view")}};

const server = createServer(serverConfg);

server.use(plugins.queryParser());
server.use(plugins.bodyParser());
server.use(cookieParser());
server.use(sessionParser("webSessionId"));

addHomeRoute(server, "");
addUserRoute(server, "/users");

process.on("SIGTERM", closeServer(server));

server.listen(process.env.WEB_PORT, () => console.log(`Listening on ${server.url}`));
