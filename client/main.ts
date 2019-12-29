import {createServer, plugins} from "restify";
import {formatHtml} from "util/formatter";
import {closeServer} from "util/middleware";
import {addHomeRoute} from "route/home/util/routing";
import {addUserRoute} from "route/user/util/routing";
import {
    getOauth2ClientCredentialsToken,
    getOauth2AuthorizationCodeToken,
} from "util/oauth2";

const getCcToken = async () => {
    const response = await getOauth2ClientCredentialsToken(
        process.env.OAUTH2_CC_CLIENT_ID,
        process.env.OAUTH2_CC_CLIENT_SECRET,
        "custom1 custom2"
    );
    return response;
};

const getAcToken = async () => {
    const response = await getOauth2AuthorizationCodeToken(
        process.env.OAUTH2_AC_CLIENT_ID,
        process.env.OAUTH2_AC_CLIENT_REDIRECT_URI,
        "offline_access openid custom1 custom2"
    );
    return response;
};

const main = async () => {
    try {
        // const response = await getCcToken();
        const response = await getAcToken();
        // console.log(response);
        console.log(
            response.statusCode,
            response.statusMessage,
            response.headers,
            response.body
        );
    } catch (error) {
        const errorReponse = {
            code: error.name,
            message: error.message,
            detail: JSON.parse(error?.response?.body ?? null),
        };
        console.error(errorReponse);
        process.exit(1);
    }
};

// main();

const serverConfg = {formatters: {"text/html": formatHtml("view")}};

const server = createServer(serverConfg);

server.use(plugins.queryParser());
server.use(plugins.bodyParser());

addHomeRoute(server, "/");
addUserRoute(server, "/users");

process.on("SIGTERM", closeServer(server));

server.listen(process.env.CLIENT_PORT, () => console.log(`Listening on ${server.url}`));
