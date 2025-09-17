// Repository for persisting tasks

use Types.Task

pub eff TaskRepo {
    def get(id: Int32): Option[Task]
    def all(): List[Task]
    def insert(t: Task): Result[String, Task]
}

mod TaskRepo {
    use Db.{insertTask, getTask, listTasks, markComplete}
    use Types.Task

    pub def newTask(id: Int32, s: String): Task =
        {id=id, title=s, isComplete = false}

    pub def runWithIO(dbPath: String, f: Unit -> a \ {TaskRepo, IO}): a \ IO =
        run { f() } with handler TaskRepo {
            def get(id, k) = k(getTask(dbPath, id))

            def all(k) = k(listTasks(dbPath))

            def insert(t, k) =
                let nt = insertTask(dbPath, t#title);
                k(Result.Ok(nt))
        }
}