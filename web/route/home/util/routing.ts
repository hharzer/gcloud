import {addRoute as addIndexRoute} from "route/home/index";
import {addRoute as addLoginRoute} from "route/home/login";

export const addHomeRoute = (server, route) => {
    addIndexRoute(server, route);
    addLoginRoute(server, route);
};
