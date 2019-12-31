import {withOauth2Token} from "util/oauth2";
import {getUser} from "route/user/util/api";

const getUserWithOauth2Token = withOauth2Token(
    process.env.OAUTH2_CC_CLIENT_ID,
    process.env.OAUTH2_CC_CLIENT_SECRET,
    "custom1 custom2",
    getUser
);

const executeRequest = async (req, res, next) => {
    try {
        const users = await getUserWithOauth2Token();
        const title = "Users";
        const homePath = "/";
        const userPath = "/users";
        const response = {title, homePath, userPath, users};
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
