import {validateMandatory, validateUserId} from "route/user/util/validation";

const parseRequest = (req, res, next) => {
    const request: any = {};
    request.userId = req.params.userId;
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const request = req.request;
    try {
        validateMandatory(request, "userId", validateUserId);
    } catch (error) {
        next(error);
    }
    next();
};

const executeRequest = (req, res, next) => {
    next();
};

const formatResponse = (req, res, next) => {
    const response: any = {};
    response.data = "GET /users/:userId";
    res.status(200);
    res.json(response);
    next();
};

export const addRoute = (server) => {
    server.get(
        "/users/:userId",
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
