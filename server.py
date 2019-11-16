import json as js
from flask import Flask, send_from_directory, request

import operate as op

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False  # JSONでの日本語文字化け対策


@app.route('/api/delete', methods=['POST'])
def delete_table():
    posted = request.get_json()
    if "table" in posted and "id" in posted:
        table = posted['table']
        id_ = posted['id']
        success = op.delete(table, id_)
        if success is True:
            msg = 'Delete: ' + table + ":" + str(id_)
        else:
            msg = f'Fail to delete:{success}'
    else:
        msg = 'Fail to delete: Wrong json'
    json = {
        'message': msg
    }
    return js.dumps(json)


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
        success = op.register_formula(jid, formula, types)
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
    arguments = ['premises_id', 'conclusion_id', 'result']
    if all([el in posted for el in arguments]):
        pre_id_text = posted['premises_id']
        c_id = posted['conclusion_id']
        result = posted['result']
        pre_id = list(map(int, pre_id_text.split('&')))
        success = op.register_theorem(pre_id, c_id, result)
        if success is True:
            msg = 'Register: ' + pre_id_text + '->' + str(c_id) + ':' + result
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
            msg = 'Update formula: ' + str(id_) + ' good: ' + str(new_good)
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
            msg = 'Transform japanese: ' + str(jid)
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
    if "premises_id" in posted and "conclusion_id" in posted:
        pre_id_text = posted['premises_id']
        c_id = posted['conclusion_id']
        pre_id = list(map(int, pre_id_text.split('&')))
        success = op.try_prove(pre_id, c_id)
        if success is True:
            msg = 'prove: ' + pre_id_text + '->' + str(c_id)
        elif success is False:
            msg = 'not proved: ' + pre_id_text + '->' + str(c_id)
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
