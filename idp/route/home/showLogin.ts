import {BadRequestError} from "restify-errors";
import {getLoginRequest, acceptLoginRequest} from "util/oauth2";

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
    try {
        const {loginChallenge} = req.request;
        const loginRequest: any = await getLoginRequest(loginChallenge);
        const {challenge, skip, subject} = loginRequest;
        if (skip) {
            const login = {subject};
            const {redirect_to: redirectTo}: any = await acceptLoginRequest(
                challenge,
                login
            );
            const response = {redirectTo};
            res.response = response;
        } else {
            const showLogin = true;
            const login = {title: "IdP - Log in", challenge};
            const response = {showLogin, ...login};
            res.response = response;
        }
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const {showLogin, redirectTo} = res.response;
    if (showLogin) {
        res.setHeader("Content-Type", "text/html");
        res.send({template: "home/login", locals: res.response});
        next();
    } else {
        res.redirect(302, redirectTo, next);
    }
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
