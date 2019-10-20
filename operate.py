from sqlite3 import connect, Error
from pathlib import Path

from ccg2lambda import j2l, prove


db_dir = Path('database')


def init(dbpath='default.sqlite'):
    database = connect(db_dir / dbpath)
    c = database.cursor()
    ret = True
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
        ret = False
        print(e)
    c.close()
    return ret
