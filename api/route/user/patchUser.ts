import {BadRequestError} from "restify-errors";
import {
    validateMandatory,
    validateOptional,
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
        const patchAttributes: boolean[] = [];
        let isPresent = false;
        isPresent = validateOptional(request, "firstName", validateFirstName);
        patchAttributes.push(isPresent);
        isPresent = validateOptional(request, "lastName", validateLastName);
        patchAttributes.push(isPresent);
        isPresent = validateOptional(request, "birthDay", validateBirthDay);
        patchAttributes.push(isPresent);
        isPresent = validateOptional(request, "nationality", validateNationality);
        patchAttributes.push(isPresent);
        isPresent = validateOptional(request, "email", validateEmail);
        patchAttributes.push(isPresent);
        if (!patchAttributes.some(Boolean)) {
            throw new BadRequestError("No attributes to patch");
        }
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
    server.patch(
        "/users/:userId",
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
