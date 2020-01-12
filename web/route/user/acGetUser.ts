import {withOauth2AuthorizationCodeToken} from "util/oauth2";
import {getUser} from "route/user/util/api";

const executeRequest = async (req, res, next) => {
    try {
        const scope = "offline_access openid custom1 custom2";
        const {sessionId, accessToken, expiresAt, refreshToken} = req?.session;
        const getUserWithOauth2AuthorizationCodeToken = withOauth2AuthorizationCodeToken(
            process.env.OAUTH2_AC_CLIENT_ID,
            process.env.OAUTH2_AC_CLIENT_SECRET,
            scope,
            sessionId,
            accessToken,
            expiresAt,
            refreshToken,
            getUser
        );
        const users = await getUserWithOauth2AuthorizationCodeToken();
        const title = "AC - Users";
        const userPath = "/ac/users";
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
    server.get(`/ac${route}`, executeRequest, formatResponse);
};
