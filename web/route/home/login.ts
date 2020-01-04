import {randomBytes} from "crypto";

// curl -sSLk -X GET "https://localhost:4444/oauth2/auth"\
// "?response_type=code&client_id=ac-client"\
// "&audience=identity&scope=offline_access openid custom1 custom2"\
// "&redirect_uri=http://localhost:4002/callback&state=randomstate"

const executeRequest = (req, res, next) => {
    const oauth2Host = process.env.OAUTH2_HOST;
    const oauth2Port = process.env.OAUTH2_PORT;
    const oauth2AuthPath = process.env.OAUTH2_AUTH_PATH;
    const clientId = process.env.OAUTH2_AC_CLIENT_ID;
    const audience = "identity";
    const scope = "offline_access openid custom1 custom2";
    const redirectUri = process.env.OAUTH2_AC_CLIENT_REDIRECT_URI;
    const state = randomBytes(16).toString("hex");
    const oauth2AuthCodeUri =
        `https://${oauth2Host}:${oauth2Port}${oauth2AuthPath}` +
        `?response_type=code&client_id=${clientId}` +
        `&audience=${audience}&scope=${scope}` +
        `&redirect_uri=${redirectUri}&state=${state}`;
    const request = {oauth2AuthCodeUri};
    req.request = request;
    next();
};

const formatResponse = (req, res, next) => {
    const {oauth2AuthCodeUri} = req.request;
    res.redirect(302, oauth2AuthCodeUri, next);
};

export const addRoute = (server, route) => {
    server.get(`${route}/login`, executeRequest, formatResponse);
};
