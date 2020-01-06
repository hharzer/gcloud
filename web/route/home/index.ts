import * as moment from "moment";
import {setCookie, deleteCookie} from "util/cookie";

const executeRequest = async (req, res, next) => {
    const title = "Web - Home";
    const userPath = "/users";
    const loginPath = "/login";
    const response = {title, userPath, loginPath};
    res.response = response;
    next();
};

const formatResponse = (req, res, next) => {
    // const attributes = {path: "/", expires: moment().add(5, "minute"), httpOnly: true};
    // setCookie(res, {webSessionId: "session1"}, attributes);
    // setCookie(res, {webSessionId2: "session2"}, attributes);

    // deleteCookie(res, "webSessionId");
    // deleteCookie(res, "webSessionId2");

    const response = res.response;
    res.header("Content-Type", "text/html");
    res.send({template: "home/index", locals: response});
    next();
};

export const addRoute = (server, route) => {
    server.get(`${route}/`, executeRequest, formatResponse);
};
