import {getOauth2AuthorizationCodeToken} from "util/oauth2";
import * as jwt from "jsonwebtoken";

const parseRequest = (req, res, next) => {
    const authCode = req.query.code;
    const scope = req.query.scope;
    const errorCode = req.query.error;
    const errorDescription = req.query.error_description;
    const state = req.query.state;
    const request = {authCode, scope, errorCode, errorDescription, state};
    req.request = request;
    next();
};

const executeRequest = async (req, res, next) => {
    const {authCode, scope, errorCode, errorDescription, state} = req.request;
    try {
        if (errorCode) {
            const errorUri = `/error?code=${errorCode}&message=${errorDescription}`;
            const response = {redirectTo: errorUri};
            res.response = response;
        } else {
            const token: any = await getOauth2AuthorizationCodeToken(
                process.env.OAUTH2_AC_CLIENT_ID,
                process.env.OAUTH2_AC_CLIENT_SECRET,
                authCode,
                scope,
                process.env.OAUTH2_AC_CLIENT_REDIRECT_URI
            );
            console.log(token);
            const idToken = jwt.decode(token.id_token);
            console.log(idToken);
            const response = {redirectTo: "/"};
            res.response = response;
        }
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const {redirectTo} = res.response;
    res.redirect(302, redirectTo, next);
};

export const addRoute = (server, route) => {
    server.get(`${route}/callback`, parseRequest, executeRequest, formatResponse);
};
