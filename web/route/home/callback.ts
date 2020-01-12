import * as moment from "moment";
import * as jwt from "jsonwebtoken";
import {getOauth2AuthorizationCodeToken} from "util/oauth2";
import {putSession} from "util/session";
import {setCookie} from "util/cookie";

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
            const {
                access_token: accessToken,
                expires_in: expiresIn,
                id_token: idToken,
                refresh_token: refreshToken,
                scope: grantedScope,
            }: any = await getOauth2AuthorizationCodeToken(
                process.env.OAUTH2_AC_CLIENT_ID,
                process.env.OAUTH2_AC_CLIENT_SECRET,
                authCode,
                scope,
                process.env.OAUTH2_AC_CLIENT_REDIRECT_URI
            );
            const {sid: sessionId, sub: subject}: any = jwt.decode(idToken);
            const expiresAt = moment()
                .add(expiresIn, "seconds")
                .subtract(5, "seconds");
            const session = {
                sessionId,
                subject,
                accessToken,
                expiresAt,
                refreshToken,
                scope: grantedScope,
            };
            putSession(sessionId, session);
            const attributes = {
                path: "/",
                expires: moment().add(5, "minute"),
                httpOnly: true,
            };
            setCookie(res, {webSessionId: sessionId}, attributes);
            const response = {redirectTo: "/ac/users"};
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
