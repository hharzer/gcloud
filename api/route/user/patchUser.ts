import {BadRequestError} from "restify-errors";
import {validateMandatory, validateOptional} from "util/validation";
import {
    validateUserId,
    validateFirstName,
    validateLastName,
    validateBirthDay,
    validateNationality,
    validateEmail,
} from "route/user/util/validation";
import {patchUser} from "route/user/util/database";

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
        next();
    } catch (error) {
        next(error);
    }
};

const executeRequest = async (req, res, next) => {
    try {
        const user = req.request;
        const userId = await patchUser(user);
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
    res.status(200);
    res.header("Location", req.path());
    res.send();
    next();
};

export const addRoute = (server, route) => {
    server.patch(
        `${route}/:userId`,
        parseRequest,
        validateRequest,
        executeRequest,
        formatResponse
    );
};
