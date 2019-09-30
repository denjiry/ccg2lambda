from flask import Flask, request, jsonify


app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False  # JSONでの日本語文字化け対策
tasks = {
    '1': 'スーパーで買い物をする',
    '2': 'Netflixを見る'
}


@app.route('/hello')
def hello_world():
    return jsonify({'message': 'Hello, world'})


@app.route('/foo/bar')
def get_foobar():
    return 'you got\n'


@app.route('/foo/bar/<int:baz>', methods=['POST'])
def post_foobar(baz):
    return 'you posted {}\n'.format(baz)


@app.route('/', methods=['POST'])
def post_json():
    json = request.get_json()  # POSTされたJSONを取得
    return jsonify(json)  # JSONをレスポンス


@app.route('/', methods=['GET'])
def get_json_from_dictionary():
    dic = {
        'foo': 'bar',
        'ほげ': 'ふが'
    }
    return jsonify(dic)  # JSONをレスポンス


@app.route('/tasks', methods=['GET'])
def list_all_tasks():
    json = {
        'message': tasks
    }
    return jsonify(json)


@app.route('/tasks/<int:taskid>', methods=['GET'])
def show_task(taskid):
    taskid = str(taskid)
    json = {
        'message': tasks[taskid]
    }
    return jsonify(json)


@app.route('/tasks/<int:taskid>', methods=['DELETE'])
def delete_task(taskid):
    taskid = str(taskid)
    if taskid in tasks:
        del tasks[taskid]
        msg = 'Task {} deleted'.format(taskid)
    else:
        msg = '{0} is not in tasks.'.format(taskid)
    json = {
        'message': msg
    }
    return jsonify(json)


@app.route('/tasks', methods=['POST'])
def create_task():
    taskid = str(int(max(tasks.keys())) + 1)
    posted = request.get_json()
    if 'task' in posted:
        tasks[taskid] = posted['task']
        msg = 'New task created'
    else:
        msg = 'No task created'
    json = {
        'message': msg
    }
    return jsonify(json)


@app.route('/tasks/<int:taskid>', methods=['PUT'])
def update_task(taskid):
    taskid = str(taskid)
    posted = request.get_json()
    if 'task' in posted and taskid in tasks:
        tasks[taskid] = posted['task']
        msg = 'Task {} updated'.format(taskid)
    else:
        msg = 'No task updated'
    json = {
        'message': msg
    }
    return jsonify(json)


if __name__ == '__main__':
    app.run(debug=True)
