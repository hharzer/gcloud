import {BadRequestError} from "restify-errors";
import {validateMandatory} from "util/validation";
import {validateUserId} from "route/user/util/validation";
import {getUser} from "route/user/util/database";

const parseRequest = (req, res, next) => {
    const request: any = {};
    request.subject = req.subject;
    request.userId = req.params.userId;
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const request = req.request;
    try {
        validateMandatory(request, "userId", validateUserId);
        next();
    } catch (error) {
        next(error);
    }
};

const executeRequest = async (req, res, next) => {
    try {
        const user = req.request;
        const users = await getUser(user);
        if (users.length !== 1) {
            throw new BadRequestError(`Non-existing userId ${user.userId}`);
        }
        const response: any = {};
        response.data = users[0];
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const user = res.response;
    res.status(200);
    res.json(user);
    next();
};

export const addRoute = (server, route) => {
    server.get(
        `${route}/:userId`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
