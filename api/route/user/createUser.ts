import {
    validateMandatory,
    validateFirstName,
    validateLastName,
    validateBirthDay,
    validateNationality,
    validateEmail,
} from "route/user/util/validation";

const parseRequest = (req, res, next) => {
    const request = req.body;
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
    } catch (error) {
        next(error);
    }
    next();
};

const executeRequest = (req, res, next) => {
    next();
};

const formatResponse = (req, res, next) => {
    res.status(201);
    res.header("Location", `${req.path()}/1`);
    res.send();
    next();
};

export const addRoute = (server) => {
    server.post(
        "/users",
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
