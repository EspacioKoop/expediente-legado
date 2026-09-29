import { configDesdeEntorno, crearHandler } from "./mando.ts";

Deno.serve(crearHandler(configDesdeEntorno()));
