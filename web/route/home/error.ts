const parseRequest = (req, res, next) => {
    const code = req.query.code;
    const message = req.query.message;
    const request = {code, message};
    req.request = request;
    next();
};

const formatResponse = (req, res, next) => {
    res.header("Content-Type", "text/html");
    res.send({template: "home/error", locals: req.request});
};

export const addRoute = (server, route) => {
    server.get(`${route}/error`, parseRequest, formatResponse);
};
