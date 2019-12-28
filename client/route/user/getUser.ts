import {getUser} from "route/user/util/database";

const executeRequest = async (req, res, next) => {
    try {
        const users = await getUser();
        const response: any = {};
        response.title = "Users";
        response.homePath = "/";
        response.userPath = "/users";
        response.users = users;
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const response = res.response;
    res.setHeader("Content-Type", "text/html");
    res.send({template: "user/getUser", locals: response});
    next();
};

export const addRoute = (server, route) => {
    server.get(route, executeRequest, formatResponse);
};
