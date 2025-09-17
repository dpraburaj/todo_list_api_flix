// Repository for persisting tasks

use Types.Task

pub eff TaskRepo {
    def get(id: Int32): Option[Task]
    def all(): List[Task]
    def insert(t: Task): Result[String, Task]
}

mod TaskRepo {
    use Types.Task

    pub def newTask(id: Int32, s: String): Task =
        {id=id, title=s, isComplete = false}

    pub def runWithIO(dbPath: String, f: Unit -> a \ ef): a \ (ef - TaskRepo - Db) + IO  =
        Db.runWithIO(dbPath, () ->
            run { f() } with handler TaskRepo {
                def get(id, k) = k(Db.getTask(id)),

                def all(k) = k(Db.listTasks()),

                def insert(t, k) =
                    let nt = Db.insertTask(t#title);
                    k(Result.Ok(nt))
            } with Db.runWithIO(dbPath)
        )
}