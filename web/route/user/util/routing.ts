import {addRoute as addCcGetUserRoute} from "route/user/ccGetUser";
import {addRoute as addAcGetUserRoute} from "route/user/acGetUser";

export const addUserRoute = (server, route) => {
    addCcGetUserRoute(server, route);
    addAcGetUserRoute(server, route);
};
