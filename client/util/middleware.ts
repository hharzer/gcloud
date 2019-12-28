export const closeServer = (server) => {
    return async () => await server.close();
};
