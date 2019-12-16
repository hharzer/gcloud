import {createServer, plugins} from "restify";
// import {requestSubject, closeServer} from "util/middleware";
// import {addUserRoute} from "route/user/util/routing";

const server = createServer();

server.use(plugins.queryParser());
server.use(plugins.bodyParser());

// addUserRoute(server, "/users");

// process.on("SIGTERM", closeServer(server));

server.listen(process.env.IDP_PORT, () => console.log(`Listening on ${server.url}`));
