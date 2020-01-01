import {addRoute as addLoginRoute} from "route/home/login";

export const addHomeRoute = (server, route) => {
    addLoginRoute(server, route);
};
