mod Types {
    // Task record type
    pub type alias Task = { id = Int32, title = String, isComplete = Bool }

    // Generic request record carries path parameters and raw body
    pub type alias Request = { pathParams = Map[String, String], body = String }

    // Simplified body type: Plain text or JSON
    pub enum BodyType with Eq, ToString {
        case Plain
        case Json
    }

    // HTTP status codes enum for type safety
    pub enum StatusCode with Eq, ToString {
        case Ok                    // 200
        case Created              // 201
        case BadRequest          // 400
        case NotFound            // 404
        case InternalServerError // 500
    }

    // Convert StatusCode to Int16 for HTTP response
    pub def statusCodeToInt(code: StatusCode): Int16 = match code {
        case StatusCode.Ok => 200i16
        case StatusCode.Created => 201i16
        case StatusCode.BadRequest => 400i16
        case StatusCode.NotFound => 404i16
        case StatusCode.InternalServerError => 500i16
    }

    // Standard HTTP response with raw body and its type
    pub type alias Response = { statusCode = StatusCode, body = String, bodyType = BodyType }
}