import {createHash} from "crypto";
import {acceptLoginRequest, rejectLoginRequest} from "util/oauth2";

const hashPassword = (password) => {
    const passwordHash = createHash("sha256")
        .update(password)
        .digest("base64");
    return passwordHash;
};

const USER_DB = {
    "volodymyrprokopyuk@gmail.com": hashPassword("vlad"),
};

const areValidCredentials = (email, password) => {
    const validPassword = USER_DB[email];
    const claimedPassword = hashPassword(password);
    const isValid = claimedPassword === validPassword;
    return isValid;
};

const parseRequest = (req, res, next) => {
    const challenge = req.body.challenge;
    const auth = req.body.auth;
    const email = req.body.email;
    const password = req.body.password;
    const remember = Boolean(req.body.remember);
    const request = {challenge, auth, email, password, remember};
    req.request = request;
    next();
};

const executeRequest = async (req, res, next) => {
    const {challenge, auth, email, password, remember} = req.request;
    try {
        if (auth === "Log in") {
            if (!areValidCredentials(email, password)) {
                throw new Error("Invalid email or password");
            }
            const login = {subject: email, remember, remember_for: 60};
            const {redirect_to: redirectTo}: any = await acceptLoginRequest(
                challenge,
                login
            );
            const response = {redirectTo};
            res.response = response;
        } else {
            const error = "login_regreted";
            const errorDescription = "Resource owner regreted to log in";
            const loginError = {error, error_description: errorDescription};
            const {redirect_to: redirectTo}: any = await rejectLoginRequest(
                challenge,
                loginError
            );
            const response = {redirectTo};
            res.response = response;
        }
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
    server.post(`${route}/login`, parseRequest, executeRequest, formatResponse);
};
