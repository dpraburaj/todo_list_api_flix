// Defines route handlers for the application

mod RouteHandlers {
    import io.javalin.http.{Context, Handler}
    use Types.{Request, BodyType, Response, Task, StatusCode, statusCodeToInt}

    // Helper functions for creating JSON responses
    pub def successResponse(data: String): Response =
        { statusCode = StatusCode.Ok,
          body = data,
          bodyType = BodyType.Json }

    pub def failureResponse(status: StatusCode, message: String): Response =
        { statusCode = status,
          body = "{\"error\":\"${message}\"}",
          bodyType = BodyType.Json }

    pub def createdResponse(data: String): Response =
        { statusCode = StatusCode.Created,
          body = data,
          bodyType = BodyType.Json }

    pub def handleTasksList(_req: Request): Response \ TaskRepo + IO =
            let ts = TaskRepo.all();
            successResponse(Json.tasksToJson(ts))

    pub def handleTaskDetail(req: Request): Response \ TaskRepo + IO =
        let idOpt =
            match Map.get("id", req#pathParams) {
                case Some(s) => Int32.fromString(s)
                case None => None
            };
        match idOpt {
            case None =>
                failureResponse(StatusCode.BadRequest, "invalid id")
            case Some(id) =>
                match TaskRepo.get(id) {
                case None =>
                    failureResponse(StatusCode.NotFound, "not found")
                case Some(t) =>
                    successResponse(Json.taskToJson(t))
                }
        }

    pub def handleNewTodo(req: Request): Response \ TaskRepo + IO =
        // Parse Task from JSON request body
        let t = Json.jsonToTask(req#body);
        let newT = TaskRepo.newTask(0, t#title);
        match TaskRepo.insert(newT) {
            case Result.Err(e) =>
                failureResponse(StatusCode.BadRequest, e)
            case Result.Ok(saved) =>
                createdResponse(Json.taskToJson(saved))
        }

    pub def makeRouteHandler(dbPath: String, routeHandler: Request -> Response \ {TaskRepo, IO}): Handler \ IO =
        // IMPORTANT: primitiveRouteHandler should only be outside new Handler for perf reasons
        // It's purpose is to get a function without custom effects so that
        // routeHandler's effects and the handle methods effects match
        let primitiveRouteHandler = (request) -> run { routeHandler(request) } with TaskRepo.runWithIO(dbPath);
        new Handler {
            def handle(_this: Handler, ctx: Context): Unit \ IO =
                // Extract path parameters and request body
                let pmap = ctx.pathParamMap();
                let request = { pathParams = Adaptor.fromMap(pmap),
                                body = ctx.body() };
                let response = primitiveRouteHandler(request);
                // Set content type based on bodyType
                if (response#bodyType == BodyType.Json) discard ctx.contentType("application/json") else ();
                // Write status and raw body
                discard ctx.status(Int16.toInt32(statusCodeToInt(response#statusCode)));
                discard ctx.result(response#body)
        }

}