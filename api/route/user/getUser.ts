import validator from "validator";
import {BadRequestError} from "restify-errors";
import {validateOptional} from "util/validation";
import {
    validateFirstName,
    validateLastName,
    validateBirthDay,
    validateNationality,
    validateEmail,
    validateLimit,
    validateOffset,
} from "route/user/util/validation";
import {getUser} from "route/user/util/database";

const parseRequest = (req, res, next) => {
    const request: any = {};
    request.subject = req.subject;
    try {
        if ("firstName" in req.query) {
            request.firstName = req.query.firstName;
        }
        if ("lastName" in req.query) {
            request.lastName = req.query.lastName;
        }
        if ("birthDay" in req.query) {
            request.birthDay = req.query.birthDay;
        }
        if ("nationality" in req.query) {
            request.nationality = req.query.nationality;
        }
        if ("email" in req.query) {
            request.email = req.query.email;
        }
        if ("limit" in req.query) {
            const limit = req.query.limit;
            if (!validator.isInt(limit)) {
                throw new BadRequestError(`Invalid limit ${limit}`);
            }
            request.limit = parseInt(limit, 10);
        }
        if ("offset" in req.query) {
            const offset = req.query.offset;
            if (!validator.isInt(offset)) {
                throw new BadRequestError(`Invalid offset ${offset}`);
            }
            request.offset = parseInt(offset, 10);
        }
        req.request = request;
        next();
    } catch (error) {
        next(error);
    }
};

const validateRequest = (req, res, next) => {
    const request = req.request;
    try {
        validateOptional(request, "firstName", validateFirstName);
        validateOptional(request, "lastName", validateLastName);
        validateOptional(request, "birthDay", validateBirthDay);
        validateOptional(request, "nationality", validateNationality);
        validateOptional(request, "email", validateEmail);
        validateOptional(request, "limit", validateLimit);
        validateOptional(request, "offset", validateOffset);
        next();
    } catch (error) {
        next(error);
    }
};

const executeRequest = async (req, res, next) => {
    try {
        const user = req.request;
        const users = await getUser(user);
        const response: any = {};
        response.data = users;
        res.response = response;
        next();
    } catch (error) {
        next(error);
    }
};

const formatResponse = (req, res, next) => {
    const users = res.response;
    res.status(200);
    res.json(users);
    next();
};

export const addRoute = (server, route) => {
    server.get(route, parseRequest, validateRequest, executeRequest, formatResponse);
};
