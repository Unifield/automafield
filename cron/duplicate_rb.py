#!/opt/unifield-venv/bin/python2.7
# -*- encoding: utf-8 -*-

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from subprocess import call
import sys
import os

config = {
    'OCA': {
        'target_user': 'oca-uf',
        'target_prefix': 'oca-uf_',
        'like_src': 'prod_%_OCA_%',
        'sync_port': '10203',
        'init_target': '/etc/init.d/oca-uf-server',
    },
    'OCB': {
        'target_user': 'ocb-uf',
        'target_prefix': 'ocb-uf_',
        'like_src': 'prod_OCB%',
        'sync_port': '10213',
        'init_target': '/etc/init.d/ocb-uf-server',
    },
    'OCG': {
        'target_user': 'ocg-uf',
        'target_prefix': 'ocg-uf_',
        'like_src': 'prod_OCG_%',
        'sync_port': '10223',
        'init_target': '/etc/init.d/ocg-uf-server',
    },
    'OCP': {
        'target_user': 'ocp-uf',
        'target_prefix': 'ocp-uf_',
        'like_src': 'prod_OCP_%',
        'sync_port': '10233',
        'init_target': '/etc/init.d/ocp-uf-server',
    }
}
OC = sys.argv[1]

target_user = config[OC]['target_user']
target_prefix = config[OC]['target_prefix']
like_src = config[OC]['like_src']
sync_port = config[OC]['sync_port']
init_target = config[OC]['init_target']


user_pass = os.environ['PASS']
src_user = 'production-dbs'
src_prefix = 'prod_'
sync_server_db = 'SYNC_SERVER_LOCAL'
init_src='/etc/init.d/production-dbs-server'

# do not connect to temlate1 during the whole process or it will block other dbs creation
# as db superuser, 'createdb -T' requires full access on src and on target
dsn='dbname=root'
db = psycopg2.connect(dsn)
db.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
cr = db.cursor()

devnull = open(os.devnull, 'w')
call([init_src, 'stop'], stdout=devnull)
call([init_target, 'stop'], stdout=devnull)

# list all dbs from source (filter on: username and pattern)
cr.execute("SELECT d.datname FROM pg_catalog.pg_database d WHERE pg_get_userbyid(d.datdba) = %s and d.datname like %s", (src_user, like_src))
src_dbs = {}
for x in cr.fetchall():
    src_dbs[x[0]] = x[0].strip(src_prefix)

# list all existing dbs on target (filter on username)
cr.execute("SELECT d.datname FROM pg_catalog.pg_database d WHERE pg_get_userbyid(d.datdba) = %s", (target_user,))
target_dbs = {}
for x in cr.fetchall():
    if 'SYNC_SERVER' not in x[0]:
        target_dbs[x[0]] = x[0].strip(target_prefix)

# if db src does not exist on target: copy
for dbname, namecut in src_dbs.iteritems():
    if 'SYNC_SERVER' in namecut:
        continue
    if '%s%s' % (target_prefix, namecut) in target_dbs:
        del target_dbs['%s%s' % (target_prefix, namecut)]
    else:
        try:
            cr.execute('CREATE DATABASE "%(target_prefix)s%(namecut)s" TEMPLATE="%(dbname)s" OWNER="%(target_user)s"' % {
                'target_prefix': target_prefix, 'namecut': namecut, 'dbname': dbname, 'target_user': target_user})
        except:
            print 'Unable to copy %s %s' % (dbname, namecut)

# sync server db: drop existing and copy from src
cr.execute('DROP DATABASE  IF EXISTS "%sSYNC_SERVER_LOCAL"' % (target_prefix,))
try:
    cr.execute('CREATE DATABASE "%(target_prefix)sSYNC_SERVER_LOCAL" TEMPLATE="%(src_prefix)sSYNC_SERVER_LOCAL" OWNER="%(target_user)s"' % {
            'target_prefix': target_prefix, 'src_prefix': src_prefix, 'target_user': target_user})
except:
    print 'Unable to copy SYNC SERVER LOCAL'

# delete remaining dbs on target
for x in target_dbs:
    cr.execute('DROP DATABASE IF EXISTS "%s"' % (x,))

# config target: set sync connection / change owner of tables as copy is done as root
cr.execute("SELECT d.datname FROM pg_catalog.pg_database d WHERE pg_get_userbyid(d.datdba) = %s", (target_user,))
for x in cr.fetchall():
    db1 = psycopg2.connect(dbname=x[0])
    cr1 = db1.cursor()
    if 'SYNC_SERVER' not in x[0]:
        cr1.execute("update sync_client_sync_server_connection set host='127.0.0.1', port=%s, database=%s, login='admin'", (sync_port, '%s%s'%(target_prefix, sync_server_db)))
    cr1.execute("update res_users set password=%s", (user_pass,))
    
    cr1.execute("select tablename from pg_tables where schemaname = 'public'")
    for xx in cr1.fetchall():
        cr1.execute('alter table "%s" owner to "%s"' % (xx[0], target_user))
    cr1.execute("select sequence_name from information_schema.sequences where sequence_schema = 'public'")
    for xx in cr1.fetchall():
        cr1.execute('alter table "%s" owner to "%s"' % (xx[0], target_user))
    cr1.execute("select table_name from information_schema.views where table_schema = 'public'")
    for xx in cr1.fetchall():
        cr1.execute('alter table "%s" owner to "%s"' % (xx[0], target_user))
    db1.commit()

call([init_src, 'start'], stdout=devnull)
call([init_target, 'start'], stdout=devnull)
