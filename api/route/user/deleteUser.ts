import {BadRequestError} from "restify-errors";
import {validateMandatory} from "util/validation";
import {validateUserId} from "route/user/util/validation";
import {deleteUser} from "route/user/util/database";

const parseRequest = (req, res, next) => {
    const subject = req.subject;
    const userId = req.params.userId;
    const request = {subject, userId};
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
        const userId = await deleteUser(user);
        if (userId === null) {
            throw new BadRequestError(`Non-existing userId ${user.userId}`);
        }
        const response = {userId};
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    res.status(204);
    res.send();
    next();
};

export const addRoute = (server, route) => {
    server.del(
        `${route}/:userId`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
