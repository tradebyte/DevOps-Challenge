import redis
from redis.exceptions import ConnectionError
import tornado.ioloop
import tornado.web

import os
from sys import exit

try:
    r = redis.Redis(
        host=os.getenv("REDIS_HOST"),
        port=int(os.getenv("REDIS_PORT")),
        db=int(os.getenv("REDIS_DB")),
    )
    r.set("counter", 0)
except ConnectionError:
    print("Redis server isn't running. Exiting...")
    exit()

environment = os.getenv("ENVIRONMENT")
port = int(os.getenv("PORT"))


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.render(
            "index.html",
            dict={"environment": environment, "counter": r.incr("counter", 1)},
        )

class LiveHandler(tornado.web.RequestHandler):
    def get(self):
        response = {"status": "live"}
        self.set_header("Content-Type", "application/json")
        self.write(response)

class ReadyHandler(tornado.web.RequestHandler):
    def get(self):
        response = {"status": "ready"}
        self.set_header("Content-Type", "application/json")
        self.write(response)

class Application(tornado.web.Application):
    def __init__(self):
        handlers = [(r"/", MainHandler), (r"/live", LiveHandler), (r"/ready", ReadyHandler)]
        settings = {
            "template_path": os.path.join(
                os.path.dirname(os.path.abspath(__file__)), "templates"
            ),
            "static_path": os.path.join(
                os.path.dirname(os.path.abspath(__file__)), "static"
            ),
        }
        tornado.web.Application.__init__(self, handlers, **settings)


if __name__ == "__main__":
    app = Application()
    app.listen(port)
    print(f"App running: http://{os.getenv('HOST')}:{int(os.getenv('PORT'))}")
    tornado.ioloop.IOLoop.current().start()
