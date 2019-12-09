import {BadRequestError} from "restify-errors";

export const validateMandatory = (request, attribute, validate) => {
    if (attribute in request) {
        validate(request[attribute]);
        return true;
    }
    throw new BadRequestError(`${attribute} is mandatory`);
};

export const validateOptional = (request, attribute, validate) => {
    if (attribute in request) {
        validate(request[attribute]);
        return true;
    }
    return false;
};
