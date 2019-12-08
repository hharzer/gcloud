import {
    validateMandatory,
    validateUserId,
    validateFirstName,
    validateLastName,
    validateBirthDay,
    validateNationality,
    validateEmail,
} from "route/user/util/validation";

const parseRequest = (req, res, next) => {
    const request = req.body;
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
    } catch (error) {
        next(error);
    }
    next();
};

const executeRequest = (req, res, next) => {
    next();
};

const formatResponse = (req, res, next) => {
    res.status(200);
    res.header("Location", `${req.path()}`);
    res.send();
    next();
};

export const addRoute = (server) => {
    server.put(
        "/users/:userId",
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
