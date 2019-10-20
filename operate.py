from sqlite3 import connect, Error
from pathlib import Path

from ccg2lambda import j2l, prove


db_dir = Path('database')


def init_db(dbpath='default.sqlite'):
    database = connect(db_dir / dbpath)
    c = database.cursor()
    init_success = True
    try:
        c.execute('''CREATE TABLE japanese
             (id integer, japanese text)''')
        c.execute('''CREATE TABLE logic
             (id integer, jid integer, formula text,
              types text, good integer)''')
        c.execute('''CREATE TABLE theorem
             (id integer, promises text,
              conclusion integer, result text)''')
    except Error as e:
        init_success = False
        print(e)
    c.close()
    return init_success


def register_japanese(japanese):
    return


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
