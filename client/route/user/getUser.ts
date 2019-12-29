import {getOauth2ClientCredentialsToken} from "util/oauth2";
import {getUser} from "route/user/util/api";

const MAX_RETRY = 2;

const withOauth2Token = (clientId, clientSecret, scope, callApi) => {
    let token: any = null;
    return async (...args) => {
        let retryCount = 0;
        while (retryCount <= MAX_RETRY) {
            console.log(`retryCount = ${retryCount}`);
            try {
                // check expiration
                if (!token || retryCount > 0) {
                    token = await getOauth2ClientCredentialsToken(
                        clientId,
                        clientSecret + "x",
                        scope
                    );
                }
                return await callApi(token.access_token, ...args);
            } catch (error) {
                // only 401 403
                console.error("CATCH", error);
                if (retryCount === MAX_RETRY) {
                    console.error("THROW", error);
                    throw error;
                }
            }
            ++retryCount;
        }
    };
};

const getUserWithOauth2Token = withOauth2Token(
    process.env.OAUTH2_CC_CLIENT_ID,
    process.env.OAUTH2_CC_CLIENT_SECRET,
    "custom1 custom2",
    getUser
);

const executeRequest = async (req, res, next) => {
    try {
        // const token: any = await getOauth2ClientCredentialsToken(
        //     process.env.OAUTH2_CC_CLIENT_ID,
        //     process.env.OAUTH2_CC_CLIENT_SECRET,
        //     "custom1 custom2"
        // );
        // const users = await getUser(token.access_token);
        const users = await getUserWithOauth2Token();
        const response: any = {};
        response.title = "Users";
        response.homePath = "/";
        response.userPath = "/users";
        response.users = users;
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const response = res.response;
    res.setHeader("Content-Type", "text/html");
    res.send({template: "user/getUser", locals: response});
    next();
};

export const addRoute = (server, route) => {
    server.get(route, executeRequest, formatResponse);
};
