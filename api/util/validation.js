"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const restify_errors_1 = require("restify-errors");
exports.validateMandatory = (request, attribute, validate) => {
    if (attribute in request) {
        validate(request[attribute]);
        return true;
    }
    throw new restify_errors_1.BadRequestError(`${attribute} is mandatory`);
};
exports.validateOptional = (request, attribute, validate) => {
    if (attribute in request) {
        validate(request[attribute]);
        return true;
    }
    return false;
};
