import {createServer, plugins} from "restify";
import {addUserRoute} from "route/user/addUserRoute";

const server = createServer();

server.use(plugins.queryParser());
server.use(plugins.bodyParser());

addUserRoute(server);

server.listen(process.env.API_PORT, () => console.log(`Listening on ${server.url}`));
