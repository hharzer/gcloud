import {createServer, plugins} from "restify";
// import {requestSubject, closeServer} from "util/middleware";
// import {addUserRoute} from "route/user/util/routing";

const formatHtml = (req, res, body) => {
    try {
        throw new Error("oh");
        return `HTML: ${body}`;
    } catch (error) {
        res.status(500);
        return `${error}`;
    }
};

const serverConfg = {
    formatters: {
        "text/html": formatHtml,
    },
};

const server = createServer(serverConfg);

server.use(plugins.queryParser());
server.use(plugins.bodyParser());

const ok = (req, res, next) => {
    // try {
    res.setHeader("Content-Type", "text/html");
    // res.send("ok");
    res.send({ok: "ok"});
    next();
    // } catch (error) {
    //     next(error);
    // }
};

server.get("/ok", ok);

// addUserRoute(server, "/users");

// process.on("SIGTERM", closeServer(server));

server.listen(process.env.IDP_PORT, () => console.log(`Listening on ${server.url}`));
