from sqlite3 import connect, Error
from pathlib import Path

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
             (id integer primary key, promises text,
              conclusion integer, result text)''')
    except Error as e:
        success = e
    conn.close()
    return success


def register_japanese(japanese):
    assert isinstance(japanese, str)
    conn = connect(DBPATH)
    c = conn.cursor()
    success = True
    try:
        c.execute('INSERT INTO japanese (japanese) VALUES (?)',
                  (japanese,))
        conn.commit()
    except Error as e:
        success = e
    conn.close()
    return success


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
    conn = connect(DBPATH)
    c = conn.cursor()
    try:
        c.execute('''INSERT INTO logic (jid, formula, types, good)
                  VALUES (?, ?, ?, ?)''',
                  (jid, formula, types, 1))
        conn.commit()
    except Error as e:
        success = e
    conn.close()
    return success


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


def transform(jid):
    japanese = fetch_japanese(jid)
    if isinstance(japanese, Error):
        return japanese  # as Exception
    dls, formulas_str = j2l(japanese)
    rets = [register_formula(jid, f, dls) for f in formulas_str]
    if all(rets):
        return True
    else:
        return rets


def try_prove(premises, conclusion):
    result_bool = prove()
    if result_bool:
        pass
    return result_bool
