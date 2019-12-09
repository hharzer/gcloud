import {createServer, plugins} from "restify";
import {requestSubject} from "util/middleware";
import {addUserRoute} from "route/user/util/routing";

const server = createServer();

server.use(plugins.queryParser());
server.use(plugins.bodyParser());
server.use(requestSubject("web"));

addUserRoute(server, "/users");

server.listen(process.env.API_PORT, () => console.log(`Listening on ${server.url}`));
