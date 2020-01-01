import got from "got";
import {BadRequestError} from "restify-errors";

const authAdmin = (() => {
    const oauth2AdminHost = process.env.OAUTH2_ADMIN_HOST;
    const oauth2AdminPort = process.env.OAUTH2_ADMIN_PORT;
    const prefixUrl = `https://${oauth2AdminHost}:${oauth2AdminPort}`;
    const options = {prefixUrl};
    const authAdminClient = got.extend(options);
    return authAdminClient;
})();

const parseRequest = (req, res, next) => {
    const loginChallenge = req.query.login_challenge;
    const request = {loginChallenge};
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const {loginChallenge} = req.request;
    try {
        if (!loginChallenge) {
            throw new BadRequestError("Missing or empty login_challenge");
        }
        next();
    } catch (error) {
        next(error);
    }
};

const executeRequest = async (req, res, next) => {
    const oauth2RequestLoginPath = process.env.OAUTH2_REQUEST_LOGIN_PATH ?? "UNDEFINED";
    const {loginChallenge} = req.request;
    const searchParams = {login_challenge: loginChallenge};
    const options = {searchParams};
    const response = await authAdmin.get(oauth2RequestLoginPath, options).json();
    console.log(response);
    next();
};

const formatResponse = (req, res, next) => {
    res.status(200);
    res.json({});
    next();
};

export const addRoute = (server, route) => {
    server.get(
        `${route}/login`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
