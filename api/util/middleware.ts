export const requestSubject = (subject) => {
    return (req, res, next) => {
        req.subject = subject;
        next();
    };
};
