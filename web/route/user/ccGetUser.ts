import {withOauth2ClientCredentialsToken} from "util/oauth2";
import {getUser} from "route/user/util/api";

const getUserWithOauth2ClientCredentialsToken = withOauth2ClientCredentialsToken(
    process.env.OAUTH2_CC_CLIENT_ID,
    process.env.OAUTH2_CC_CLIENT_SECRET,
    "identity",
    "custom1 custom2",
    getUser
);

const executeRequest = async (req, res, next) => {
    try {
        const users = await getUserWithOauth2ClientCredentialsToken();
        const title = "CC - Users";
        const userPath = "/cc/users";
        const response = {title, userPath, users};
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const response = res.response;
    res.header("Content-Type", "text/html");
    res.send({template: "user/getUser", locals: response});
    next();
};

export const addRoute = (server, route) => {
    server.get(`/cc${route}`, executeRequest, formatResponse);
};
