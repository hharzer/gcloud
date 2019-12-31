const executeRequest = async (req, res, next) => {
    const title = "Welcome home";
    const userPath = "/users";
    const response = {title, userPath};
    res.response = response;
    next();
};

const formatResponse = (req, res, next) => {
    const response = res.response;
    res.setHeader("Content-Type", "text/html");
    res.send({template: "home/home", locals: response});
    next();
};

export const addRoute = (server, route) => {
    server.get(route, executeRequest, formatResponse);
};
