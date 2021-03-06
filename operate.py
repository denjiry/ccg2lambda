from sqlite3 import connect, Error
from pathlib import Path
import json

from scripts.logic_parser import logic_parser, LogicalExpressionException
from ccg2lambda import j2l, prove


DBPATH = Path('database') / 'default.sqlite'


def init_db():
    conn = connect(DBPATH)
    c = conn.cursor()
    success = True
    try:
        c.execute('''CREATE TABLE japanese
             (id integer primary key, japanese text)''')
        c.execute('''CREATE TABLE logic
             (id integer primary key, jid integer, formula text,
              types text, good integer)''')
        c.execute('''CREATE TABLE theorem
             (id integer primary key, premises text,
              conclusion integer, result text)''')
    except Error as e:
        success = e
    conn.close()
    return success


def _ex(query_str, arg_tuple):
    conn = connect(DBPATH)
    c = conn.cursor()
    success = True
    try:
        c.execute(query_str, arg_tuple)
        conn.commit()
    except Error as e:
        success = e
    conn.close()
    return success


def register_japanese(japanese):
    assert isinstance(japanese, str)
    dls, formulas_str = j2l(japanese)
    _ex('INSERT INTO japanese (japanese) VALUES (?)',
        (japanese,))
    jid = japanese2jid(japanese)
    rets = [register_formula(jid, f, dls) for f in set(formulas_str)]
    if all(rets):
        return True
    else:
        return rets


def japanese2jid(japanese):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute('SELECT id FROM japanese WHERE japanese = ?',
                  (japanese,))
        jid = c.fetchone()[0]
        conn.close()
    except Error as e:
        conn.close()
        return e
    return jid


def register_formula(jid, formula, types):
    success = True
    assert isinstance(formula, str) and isinstance(types, str)
    # reject formula that cannot be parsed
    try:
        logic_parser.parse(formula)
    except LogicalExpressionException as e:
        success = e
        return success
    # register formula
    success = _ex('''INSERT INTO logic (jid, formula, types, good)
                  VALUES (?, ?, ?, ?)''',
                  (jid, formula, types, 1))
    return success


def register_theorem(premises_id, conclusion_id, result_bool):
    premises_id_text = ' & '.join(map(str, premises_id))
    result_text = 'proved' if result_bool else 'not proved'
    success = _ex('''INSERT INTO theorem (premises, conclusion, result)
                  VALUES (?, ?, ?)''',
                  (premises_id_text, conclusion_id, result_text))
    return success


def update_formula_good(id_, new_good):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute('UPDATE logic SET good = ? WHERE id = ?',
                  (new_good, id_))
        conn.commit()
        conn.close()
    except Error as e:
        conn.close()
        return e
    return True


def fetch_japanese(jid):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute('SELECT japanese FROM japanese WHERE id = ?',
                  (jid,))
        japanese = c.fetchone()[0]
        conn.close()
    except Error as e:
        conn.close()
        return e
    return japanese


def fetch_formula(fid):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute('SELECT formula, types FROM logic WHERE id = ?',
                  (fid,))
        formula, types = c.fetchone()
        conn.close()
    except Error as e:
        conn.close()
        return e, e
    return formula, types


def try_prove(premises_id, conclusion_id):
    # fetch formulas
    premises, dls = [], []
    for pid in premises_id:
        p, pdls = fetch_formula(pid)
        premises.append(p)
        dls.append(pdls)
    conclusion, c_dls = fetch_formula(conclusion_id)
    dls.append(c_dls)
    # check SQL error
    error_list = [pre for pre in premises if isinstance(pre, Error)]
    error_list += [conclusion] if isinstance(conclusion, Error) else []
    if len(error_list) > 0:
        return error_list
    # try to prove a theorem : pre1 -> ... -> conclusion
    result_bool = prove(premises, conclusion, dls)
    register_theorem(premises_id, conclusion_id, result_bool)
    return result_bool


def _fall(sqquery):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute(sqquery)
        ret = c.fetchall()
        conn.close()
    except Error as e:
        conn.close()
        return e
    return ret


def info_japanese():
    japanese = _fall('SELECT id, japanese FROM japanese')
    return japanese


def info_logic():
    logic_table = _fall('SELECT id, jid, formula, types, good FROM logic')
    return logic_table


def info_formulas_from_jid(jid):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute('SELECT id, formula, types, good FROM logic WHERE jid = ?',
                  (jid,))
        formulas = c.fetchall()
        conn.close()
    except Error as e:
        conn.close()
        return e
    return formulas


def info_theorem():
    theorems = _fall('SELECT id, premises, conclusion, result FROM theorem')
    return theorems


def delete(table, id_):
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute(f'DELETE FROM {table} WHERE id = ? ',
                  (id_,))
        conn.commit()
        conn.close()
    except Error as e:
        conn.close()
        return e
    return True


def dumptable(filename):
    japanese = info_japanese()
    logic_table = info_logic()
    theorems = info_theorem()
    alltable = {"jatable": japanese,
                "lotable": logic_table,
                "thtable": theorems}
    alltablejs = json.dumps(alltable, indent=4)
    with open(filename, 'w') as f:
        f.write(alltablejs)
    return


def load_alltable(jsonfilename):
    with open(jsonfilename, 'r') as f:
        loaded_json = json.load(f)
    jatable = loaded_json['jatable']
    lotable = loaded_json['lotable']
    thtable = loaded_json['thtable']
    for _, japanese in jatable:
        _ex('INSERT INTO japanese (japanese) VALUES (?)',
            japanese)

    for _, jid, formula, types, good in lotable:
        _ex('''INSERT INTO logic (jid, formula, types, good)
            VALUES (?, ?, ?, ?)''',
            (jid, formula, types, good))

    for _, premises_id_text, c_id, result_text in thtable:
        _ex('''INSERT INTO theorem (premises, conclusion, result)
            VALUES (?, ?, ?)''',
            (premises_id_text, c_id, result_text))
    return
