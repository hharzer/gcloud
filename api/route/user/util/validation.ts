import * as moment from "moment";
import validator from "validator";
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

export const validateUserId = (userId) => {
    if (!validator.isUUID(userId, 4)) {
        throw new BadRequestError(`Invalid userId ${userId}`);
    }
};

export const validateFirstName = (firstName) => {
    if (!/^[A-Z][- a-zA-Z]{1,}$/.test(firstName)) {
        throw new BadRequestError(`Invalid firstName ${firstName}`);
    }
};

export const validateLastName = (lastName) => {
    if (!/^[A-Z][- a-zA-Z]{1,}$/.test(lastName)) {
        throw new BadRequestError(`Invalid lastName ${lastName}`);
    }
};

export const validateBirthDay = (birthDay) => {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(birthDay)) {
        throw new BadRequestError(`Invalid birthDay ${birthDay}`);
    }
    if (!moment(birthDay, "YYYY-MM-DD").isValid()) {
        throw new BadRequestError(`Invalid birthDay ${birthDay}`);
    }
};

export const validateNationality = (nationality) => {
    if (!/^[A-Z][- a-zA-Z]{3,}$/.test(nationality)) {
        throw new BadRequestError(`Invalid nationality ${nationality}`);
    }
};

export const validateEmail = (email) => {
    if (!validator.isEmail(email)) {
        throw new BadRequestError(`Invalid email ${email}`);
    }
};

export const validateLimit = (limit) => {
    if (limit < 10 || limit > 100) {
        throw new BadRequestError(`limit ${limit} out of range`);
    }
};

export const validateOffset = (offset) => {
    if (offset < 0 || offset > 10000) {
        throw new BadRequestError(`offset ${offset} out of range`);
    }
};
