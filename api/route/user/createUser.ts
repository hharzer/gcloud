import {validateMandatory} from "util/validation";
import {
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
    req.request = request;
    next();
};

const validateRequest = (req, res, next) => {
    const request = req.request;
    try {
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
        const response: any = {};
        response.userId = userId;
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const user = res.response;
    res.status(201);
    res.header("Location", `${req.path()}/${user.userId}`);
    res.send();
    next();
};

export const addRoute = (server, route) => {
    server.post(route, parseRequest, validateRequest, executeRequest, formatResponse);
};
