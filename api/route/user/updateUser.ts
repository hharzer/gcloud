import {validateMandatory} from "util/validation";
import {
    validateUserId,
    validateFirstName,
    validateLastName,
    validateBirthDay,
    validateNationality,
    validateEmail,
} from "route/user/util/validation";
import {putUser} from "route/user/util/database";

const parseRequest = (req, res, next) => {
    const request = req.body;
    request.subject = req.subject;
    request.userId = req.params.userId;
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const request = req.request;
    try {
        validateMandatory(request, "userId", validateUserId);
        validateMandatory(request, "firstName", validateFirstName);
        validateMandatory(request, "lastName", validateLastName);
        validateMandatory(request, "birthDay", validateBirthDay);
        validateMandatory(request, "nationality", validateNationality);
        validateMandatory(request, "email", validateEmail);
        next();
    } catch (error) {
        next(error);
    }
};

const executeRequest = async (req, res, next) => {
    try {
        const user = req.request;
        const userId = await putUser(user);
        const response = {userId};
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    res.status(200);
    res.header("Location", req.path());
    res.send();
    next();
};

export const addRoute = (server, route) => {
    server.put(
        `${route}/:userId`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
