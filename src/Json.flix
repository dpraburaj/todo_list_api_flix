mod Json {
    import com.fasterxml.jackson.databind.ObjectMapper
    import java.util.LinkedHashMap
    import java.util.ArrayList
    import java.lang.Integer
    import java.lang.Boolean
    use Types.Task

    pub def createObjectMapper(): ObjectMapper \ IO =
        new ObjectMapper()

    pub def taskToJavaMap(t: Task): LinkedHashMap \ IO =
        let m = new LinkedHashMap();
        discard m.put("id", Integer.valueOf(t#id));
        discard m.put("title", t#title);
        discard m.put("isComplete", Boolean.valueOf(t#isComplete));
        m

    pub def taskToJson(t: Task): String \ IO =
        let mapper = createObjectMapper();
        let map = taskToJavaMap(t);
        mapper.writeValueAsString(map)

    pub def tasksToJson(ts: List[Task]): String \ IO =
        let mapper = createObjectMapper();
        let arr = new ArrayList();
        List.forEach(t -> { discard arr.add(taskToJavaMap(t)) }, ts);
        mapper.writeValueAsString(arr)

    // Parse a JSON string into a Flix Task record using JsonNode
    pub def jsonToTask(s: String): Task \ IO =
        let mapper = createObjectMapper();
        // Parse into a JsonNode
        let node = mapper.readTree(s);
        // Extract fields
        let id = node.get("id").asInt();
        let title = node.get("title").asText();
        let isComplete = node.get("isComplete").asBoolean();
        { id = id, title = title, isComplete = isComplete }
}
