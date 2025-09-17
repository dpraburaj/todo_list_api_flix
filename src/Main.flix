mod WebServer {
    import io.javalin.Javalin
    import java.lang.Thread
    import io.javalin.http.{Context, Handler}
    use RouteHandlers.{handleTasksList, handleTaskDetail, handleNewTodo, makeRouteHandler}

    pub def start(): Unit \ IO =
        // Initialize SQLite DB 
        let dbName = "data.db";
        run {
            Db.init()
        } with Db.runWithIO(dbName);

        // Curried function for convenience
        let routeHandler = makeRouteHandler(dbName);

        // Define route
        let app = Javalin.create();
        app.get("/api/todos", routeHandler(handleTasksList));
        app.post("/api/todos", routeHandler(handleNewTodo));
        app.get("/api/todos/{id}", routeHandler(handleTaskDetail));

        // Start server
        app.start(8080);
        println("Press Ctrl+C to stop");

        // Keep the main thread alive
        Thread.currentThread().join()
}

def main(): Unit \ IO =
    WebServer.start()