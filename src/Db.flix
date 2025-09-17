// Module for direct SQL operations

use Types.Task

pub eff Db {
    def init(): Unit
    def insertTask(title: String): {id = Int32, title = String, isComplete = Bool}
    def getTask(id: Int32): Option[{id = Int32, title = String, isComplete = Bool}]
    def listTasks(): List[{id = Int32, title = String, isComplete = Bool}]
    def markComplete(id: Int32): Result[String, {id = Int32, title = String, isComplete = Bool}]
}

mod Db {
    import java.sql.{DriverManager, ResultSet, Connection}
    import java.lang.Class

    def withConnection(dbPath: String, f: Connection -> a \ IO): a \ IO =
        let url = "jdbc:sqlite:${dbPath}";
        let conn = DriverManager.getConnection(url);
        let res = f(conn);
        conn.close();
        res

    def initDb(dbPath: String): Unit \ IO =
        Class.forName("org.sqlite.JDBC");
        let url = "jdbc:sqlite:${dbPath}";
        let conn = DriverManager.getConnection(url);
        let stmt = conn.createStatement();
        let sql = "CREATE TABLE IF NOT EXISTS tasks (\n" +
                  "  id INTEGER PRIMARY KEY AUTOINCREMENT,\n" +
                  "  title TEXT NOT NULL,\n" +
                  "  is_complete INTEGER NOT NULL DEFAULT 0\n" +
                  ")";
        stmt.execute(sql);
        stmt.close();
        conn.close()

    def insertTaskDb(dbPath: String, title: String): {id = Int32, title = String, isComplete = Bool} \ IO =
        withConnection(dbPath, conn -> {
            let ps = conn.prepareStatement("INSERT INTO tasks (title, is_complete) VALUES (?, 0)");
            ps.setString(1, title);
            ps.executeUpdate();
            let rs = conn.createStatement().executeQuery("SELECT last_insert_rowid()");
            rs.next();
            let nid = rs.getInt(1);
            rs.close();
            ps.close();
            {id = nid, title = title, isComplete = false}
        })

    def getTaskDb(dbPath: String, id: Int32): Option[{id = Int32, title = String, isComplete = Bool}] \ IO =
        withConnection(dbPath, conn -> {
            let ps = conn.prepareStatement("SELECT id, title, is_complete FROM tasks WHERE id = ?");
            ps.setInt(1, id);
            let rs = ps.executeQuery();
            let res =
                if (rs.next()) {
                    Some(readTask(rs))
                } else None;
            rs.close();
            ps.close();
            res
        })

    def listTasksDb(dbPath: String): List[{id = Int32, title = String, isComplete = Bool}] \ IO =
        withConnection(dbPath, conn -> {
            let ps = conn.prepareStatement("SELECT id, title, is_complete FROM tasks ORDER BY id");
            let rs = ps.executeQuery();
            let res = readTasks(rs, Nil);
            rs.close();
            ps.close();
            res
        })

    def markCompleteDb(dbPath: String, id: Int32): Result[String, {id = Int32, title = String, isComplete = Bool}] \ IO =
        withConnection(dbPath, conn -> {
            let ps = conn.prepareStatement("UPDATE tasks SET is_complete = 1 WHERE id = ?");
            ps.setInt(1, id);
            let count = ps.executeUpdate();
            ps.close();
            if (count == 0) {
                Result.Err("Task not found")
            } else {
                let ps2 = conn.prepareStatement("SELECT id, title, is_complete FROM tasks WHERE id = ?");
                ps2.setInt(1, id);
                let rs = ps2.executeQuery();
                rs.next();
                let t = readTask(rs);
                rs.close();
                ps2.close();
                Result.Ok(t)
            }
        })

    def readTasks(rs: ResultSet, acc: List[{id = Int32, title = String, isComplete = Bool}]): List[{id = Int32, title = String, isComplete = Bool}] \ IO =
        if (rs.next()) {
            let t = readTask(rs);
            readTasks(rs, t :: acc)
        } else List.reverse(acc)

    def readTask(rs: ResultSet): {id = Int32, title = String, isComplete = Bool} \ IO =
        let rid = rs.getInt(1);
        let title = rs.getString(2);
        let isC = rs.getInt(3) != 0;
        {id=rid, title=title, isComplete=isC}

    pub def runWithIO(dbPath: String, f: Unit -> a \ ef): a \ ef - Db + IO =
        run { f() } with handler Db {
            def init(k) = k(initDb(dbPath))

            def insertTask(title, k) = k(insertTaskDb(dbPath, title))

            def getTask(id, k) = k(getTaskDb(dbPath, id))

            def listTasks(k) = k(listTasksDb(dbPath))

            def markComplete(id, k) = k(markCompleteDb(dbPath, id))
        }
}
