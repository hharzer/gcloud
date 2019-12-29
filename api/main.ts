import {createServer, plugins} from "restify";
import {verifyOauth2Token, requestSubject, closeServer} from "util/middleware";
import {addUserRoute} from "route/user/util/routing";

const server = createServer();

server.use(plugins.queryParser());
server.use(plugins.bodyParser());
server.use(verifyOauth2Token("/users"));
server.use(requestSubject("web"));

addUserRoute(server, "/users");

process.on("SIGTERM", closeServer(server));

server.listen(process.env.API_PORT, () => console.log(`Listening on ${server.url}`));
