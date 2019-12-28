import {createServer, plugins} from "restify";
import {createHtmlFormatter} from "util/formatter";
import {closeServer} from "util/middleware";
// import {addUserRoute} from "route/user/util/routing";

const formatHtml = createHtmlFormatter("view");
const serverConfg = {formatters: {"text/html": formatHtml}};

const server = createServer(serverConfg);

server.use(plugins.queryParser());
server.use(plugins.bodyParser());

const ok = (req, res, next) => {
    const response = {title: "Default title", name: "Vlad"};
    res.setHeader("Content-Type", "text/html");
    res.send({template: "index", locals: response});
    next();
};

server.get("/ok", ok);

// addUserRoute(server, "/users");

process.on("SIGTERM", closeServer(server));

server.listen(process.env.IDP_PORT, () => console.log(`Listening on ${server.url}`));
