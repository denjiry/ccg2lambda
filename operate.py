from sqlite3 import connect, Error
from pathlib import Path

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


def register_formula(formula):
    return


def transform(jid):
    dls, formula_str = j2l()
    return


def try_prove(premises, conclusion):
    result_bool = prove()
    if result_bool:
        pass
    return result_bool
