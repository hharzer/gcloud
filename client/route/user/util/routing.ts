import {addRoute as addGetUserRoute} from "route/user/getUser";

export const addUserRoute = (server, route) => {
    addGetUserRoute(server, route);
};
