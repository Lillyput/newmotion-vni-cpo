import flask

app = flask.Flask(__name__)

#Running healthcheck on port 5000
@app.route('/health_check', methods=['GET'])
def health_check():
    return {"status":"pass"}
app.run(host='0.0.0.0')