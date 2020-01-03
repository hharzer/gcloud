import {acceptLoginRequest} from "util/oauth2";

const parseRequest = (req, res, next) => {
    const challenge = req.body.challenge;
    const email = req.body.email;
    const password = req.body.password;
    const remember = Boolean(req.body.remember);
    const request = {challenge, email, password, remember};
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const {challenge, email, password} = req.request;
    try {
        if (!email) {
            throw new Error("Missing or empty email");
        }
        if (!password) {
            throw new Error("Missing or empty password");
        }
        next();
    } catch (error) {
        const response = {challenge, error: error.message};
        res.setHeader("Content-Type", "text/html");
        res.send({template: "home/login", locals: response});
        next(false);
    }
};

const executeRequest = async (req, res, next) => {
    const {challenge, email, password, remember} = req.request;
    try {
        if (email !== "volodymyrprokopyuk@gmail.com" || password !== "vlad") {
            throw new Error("Invalid email or password");
        }
        const login = {subject: email, remember, remember_for: 60};
        const {redirect_to}: any = await acceptLoginRequest(challenge, login);
        const response = {redirectTo: redirect_to};
        res.response = response;
        next();
    } catch (error) {
        const response = {challenge, error: error.message};
        res.setHeader("Content-Type", "text/html");
        res.send({template: "home/login", locals: response});
        next(false);
    }
};

const formatResponse = (req, res, next) => {
    const {redirectTo} = res.response;
    res.redirect(302, redirectTo, next);
};

export const addRoute = (server, route) => {
    server.post(
        `${route}/login`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
