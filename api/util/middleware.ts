import {databasePool} from "util/database";

export const requestSubject = (subject) => {
    return (req, res, next) => {
        req.subject = subject;
        next();
    };
};

export const closeServer = (server) => {
    return async () => {
        await server.close();
        await databasePool().end();
    };
};
