const executeRequest = async (req, res, next) => {
    const title = "Web - Home";
    const userPath = "/users";
    const loginPath = "/login";
    const response = {title, userPath, loginPath};
    res.response = response;
    next();
};

const formatResponse = (req, res, next) => {
    const response = res.response;
    res.setHeader("Content-Type", "text/html");
    res.send({template: "home/index", locals: response});
    next();
};

export const addRoute = (server, route) => {
    server.get(`${route}/`, executeRequest, formatResponse);
};
