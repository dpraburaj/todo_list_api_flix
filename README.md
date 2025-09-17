# Todo List

This is a minimal todo list API service written in Flix. It uses the [Javalin](https://javalin.io) web framework with Flix's Java interop support. It uses SQLite as the database.

## Running

Use `flix run` to start the app, and `flix test` to run the automated tests(no tests currently!).

## API

### List Todos
```bash
curl -s http://localhost:8080/api/todos | jq
```

### Get Todo by ID
```bash
curl -s http://localhost:8080/api/todos/1 | jq
```

### Create a New Todo
```bash
curl -s -X POST http://localhost:8080/api/todos \
     -H "Content-Type: application/json" \
     -d '{"id":0,"title":"Buy milk","isComplete":false}' | jq
```

## Benchmarking

### Prerequisites

**Note:** Make sure to start the application first with `flix run` in one terminal before running benchmarks.

Install [wrk](https://github.com/wg/wrk) for HTTP benchmarking:

#### macOS with Homebrew
```bash
brew install wrk
```

#### Ubuntu/Debian
```bash
sudo apt-get install wrk
```

#### Build from Source
```bash
git clone https://github.com/wg/wrk.git
cd wrk
make
sudo cp wrk /usr/local/bin/
```

### Reading Todos (GET)

Benchmark the list todos endpoint:

```bash
wrk -t4 -c100 -d5s http://localhost:8080/api/todos
```

**Example Output** (Run on a 10-core Mac mini):

```
wrk -t4 -c100 -d30s http://localhost:8080/api/todos
Running 30s test @ http://localhost:8080/api/todos
  4 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.31ms    4.61ms  94.05ms   92.35%
    Req/Sec     9.51k     3.47k   26.87k    75.48%
  549824 requests in 14.58s, 205.55MB read
Requests/sec:  37714.67
Transfer/sec:     14.10MB
```

This runs for 5 seconds with 4 threads and 100 concurrent connections.

### Writing Todos (POST)

First, create a Lua script for POST requests (`post_todo.lua`):

```lua
wrk.method = "POST"
wrk.body = '{"id":0,"title":"Benchmark todo","isComplete":false}'
wrk.headers["Content-Type"] = "application/json"

-- Generate unique titles to avoid conflicts
counter = 0

request = function()
    counter = counter + 1
    wrk.body = '{"id":0,"title":"Benchmark todo ' .. counter .. '","isComplete":false}'
    return wrk.format(nil, "/api/todos")
end
```

Then benchmark the create todo endpoint:

```bash
wrk -t4 -c5 -d5s -s post_todo.lua http://localhost:8080/api/todos
```

This runs for 5 seconds with 4 threads and 5 concurrent connections (fewer for writes to avoid overwhelming the database).

**Example Output:**

```
$ wrk -t4 -c5 -d5s -s post_todo.lua http://localhost:8080/api/todos
Running 5s test @ http://localhost:8080/api/todos
  4 threads and 5 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    48.48ms  111.83ms 781.18ms   89.70%
    Req/Sec   783.66    734.56     2.89k    77.86%
  12240 requests in 5.04s, 2.03MB read
Requests/sec:   2430.06
Transfer/sec:    412.06KB
```

**Note:** Writes can improved a lot(I got 10K/s with a test) by modifying SQLite pragmas for the DB by following things similar to [https://fractaledmind.com/2023/09/07/enhancing-rails-sqlite-fine-tuning/](Article). 

The benchmarks are just posted for curiosity, I wouldn't use SQLite for production apps/services with concurrent users.

## Useful Flix Docs

**Note:** This section is for LLMs/code agents to lookup Flix docs easily

- Language tutorial: [https://doc.flix.dev](https://doc.flix.dev)
- API reference: [https://api.flix.dev](https://api.flix.dev)
