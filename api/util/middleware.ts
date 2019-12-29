import {UnauthorizedError, ForbiddenError} from "restify-errors";
import {introspectOAuth2Token} from "util/oauth2";
import {databasePool} from "util/database";

export const verifyOauth2Token = (...paths) => {
    return async (req, res, next) => {
        try {
            if (paths.some((path) => req.path().startsWith(path))) {
                const authorization = req.header("Authorization");
                if (!authorization) {
                    throw new UnauthorizedError("Missing Authorization header");
                }
                const match = authorization.match(/^Bearer (.+)$/i);
                if (!match) {
                    throw new UnauthorizedError("Missing access token");
                }
                const accessToken = match[1];
                const token: any = await introspectOAuth2Token(accessToken, "");
                if (!token.active) {
                    throw new ForbiddenError("Expired or invalid access token");
                }
            }
            next();
        } catch (error) {
            next(error);
        }
    };
};

export const requestSubject = (subject) => {
    return (req, res, next) => {
        req.subject = subject;
        next();
    };
};

export const closeServer = (server) => {
    return async () => {
        await server.close();
        await databasePool().end();
    };
};
