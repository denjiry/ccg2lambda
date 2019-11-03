import json as js
from flask import Flask, send_from_directory, request, jsonify

import operate as op

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


@app.route('/hoge', methods=['GET'])
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


@app.route('/api/reg_ja', methods=['POST'])
def reg_ja():
    posted = request.get_json()
    if 'japanese' in posted:
        ja = posted['japanese']
        success = op.register_japanese(ja)
        if success is True:
            msg = 'Register: ' + ja
        else:
            msg = 'Fail to register:' + success
    else:
        msg = 'Fail to register: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


@app.route('/api/reg_lo', methods=['POST'])
def reg_lo():
    posted = request.get_json()
    if ('jid' in posted)and('formula' in posted)and('types' in posted):
        jid = posted['jid']
        formula = posted['formula']
        types = posted['types']
        success = op.register_japanese(jid, formula, types)
        if success is True:
            msg = 'Register: jid=' + jid + ': ' + formula
            msg += ': types[' + types + ']'
        else:
            msg = 'Fail to register:' + success
    else:
        msg = 'Fail to register: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


@app.route('/api/reg_th', methods=['POST'])
def reg_th():
    posted = request.get_json()
    arguments = ['premises_id', 'conclusion_id', 'result_bool']
    if all([el in posted for el in arguments]):
        pre_id_text = posted['premises_id']
        c_id = posted['conclusion_id']
        result_bool = posted['result_bool']
        pre_id = list(map(int, pre_id_text.split('&')))
        success = op.register_theorem(pre_id, c_id, result_bool)
        if success is True:
            msg = 'Register: ' + pre_id_text + '->' + c_id + ':' + result_bool
        else:
            msg = 'Fail to register:' + success
    else:
        msg = 'Fail to register: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


@app.route('/api/update_good', methods=['POST'])
def update_good():
    posted = request.get_json()
    if 'id' in posted and 'new_good' in posted:
        id_ = posted['id']
        new_good = posted['new_good']
        success = op.update_formula_good(id_, new_good)
        if success is True:
            msg = 'Update formula: ' + id_ + ' good: ' + new_good 
        else:
            msg = 'Fail to update:' + success
    else:
        msg = 'Fail to update: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


@app.route('/api/transform', methods=['POST'])
def transform():
    posted = request.get_json()
    if 'jid' in posted:
        jid = posted['jid']
        success = op.transform(jid)
        if success is True:
            msg = 'Transform japanese: ' + jid
        else:
            msg = 'Fail to transform:' + success
    else:
        msg = 'Fail to transform: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


@app.route('/api/try_prove', methods=['POST'])
def try_prove():
    posted = request.get_json()
    if ('jid' in posted)and('formula' in posted)and('types' in posted):
        pre_id_text = posted['premises_id']
        c_id = posted['conclusion_id']
        pre_id = list(map(int, pre_id_text.split('&')))
        success = op.try_prove(pre_id, c_id)
        if success is True:
            msg = 'prove: ' + pre_id_text + '->' + c_id
        else:
            msg = 'Fail to prove: one of errors:' + success[0]
    else:
        msg = 'Fail to prove: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


@app.route('/api/alltable', methods=['GET'])
def alltable():
    japanese = op.info_japanese()
    logic_table = op.info_logic()
    theorems = op.info_theorem()
    alltable = {"jatable": japanese,
                "lotable": logic_table,
                "thtable": theorems}
    return js.dumps(alltable)


@app.route('/')
def root():
    init_response = op.init_db()
    if init_response is True:
        print("DB message: initialized now.")
    elif isinstance(init_response, op.Error):
        print("DB message:", init_response)
    else:
        assert False
    return send_from_directory('.', 'main.html')


if __name__ == '__main__':
    app.run(port=9999, host='localhost', debug=True)
