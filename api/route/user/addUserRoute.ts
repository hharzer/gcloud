import {addRoute as addCreateUserRoute} from "route/user/createUser";
import {addRoute as addGetUserRoute} from "route/user/getUser";
import {addRoute as addGetUserByIdRoute} from "route/user/getUserById";
import {addRoute as addUpdateUserRoute} from "route/user/updateUser";
import {addRoute as addPatchUserRoute} from "route/user/patchUser";
import {addRoute as addDeleteUserRoute} from "route/user/deleteUser";

export const addUserRoute = (server) => {
    addCreateUserRoute(server);
    addGetUserRoute(server);
    addGetUserByIdRoute(server);
    addUpdateUserRoute(server);
    addPatchUserRoute(server);
    addDeleteUserRoute(server);
};
