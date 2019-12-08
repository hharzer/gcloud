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
    res.status(204);
    res.send();
    next();
};

export const addRoute = (server) => {
    server.del(
        "/users/:userId",
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
