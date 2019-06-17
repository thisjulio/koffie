import koffie
import json

def teste(req, res):
    a = req.get_body()
    hw = ''#json.dumps(dict(hello="world!"))
    res.set_body(hw.encode("utf8"))

app = koffie.Server()

app.register_endpoint(b"/teste/", teste)

app.listen(32001, b"localhost")