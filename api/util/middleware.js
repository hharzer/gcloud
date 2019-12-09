"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requestSubject = (subject) => {
    return (req, res, next) => {
        req.subject = subject;
        next();
    };
};
