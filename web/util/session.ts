const SESSION_STORE = {};

export const putSession = (sessionId, session) => {
    SESSION_STORE[sessionId] = session;
};

export const getSession = (sessionId) => {
    const session = SESSION_STORE[sessionId];
    return session;
};

export const sessionParser = (sessionCookieName) => {
    return (req, res, next) => {
        const sessionId = req?.cookies?.[sessionCookieName];
        if (sessionId) {
            const session = getSession(sessionId);
            req.session = session;
        }
        next();
    };
};
