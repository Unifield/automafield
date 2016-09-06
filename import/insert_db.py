#encoding=utf-8

import datetime
from paramiko import SSHClient, AutoAddPolicy
import os.path, sys, fnmatch, os, re, time
import easywebdav
import subprocess

from time import mktime
from datetime import datetime

from zipfile import *

import tempfile
import sys

import urllib3
http = urllib3.PoolManager()

import logging
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
ch = logging.StreamHandler(stream=sys.stderr)
ch.setLevel(logging.WARNING)
logging.root.addHandler(ch)

HWID = sys.argv[1]

POSTGRESQL_USERNAME = sys.argv[2]
POSTGRESQL_PASSWORD = sys.argv[3]

POSTGRESQL_PORT = int(sys.argv[4])

ctid = int(sys.argv[5])
POSTGRESQL_SERVER = 'ct%d' % ctid

OWNCLOUD_DIRECTORY = sys.argv[6]
OWNCLOUD_USERNAME = sys.argv[7]
OWNCLOUD_PASSWORD = sys.argv[8]

LOGIN_BACKUPS = sys.argv[9]
PASSWORD_BACKUPS = sys.argv[10]

instances_to_download = sys.argv[12:]

def match_instance_name(instance_to_download, db_name):
    instance_to_download = '^' + '.*'.join(map(lambda x : re.escape(x), instance_to_download.split('%'))) + '$'

    return bool(re.match(instance_to_download, db_name))

def match_any_wildcard(db_name):
    if not instances_to_download:
        return True

    for instance_to_download in instances_to_download:
        if match_instance_name(instance_to_download, db_name):
            return True
    return False

def run_script(dbname, script):
    scriptfile = tempfile.mkstemp()
    f = os.fdopen(scriptfile[0], 'w')
    f.write(script)
    f.close()

    os.environ['PGPASSWORD'] = POSTGRESQL_PASSWORD
    ret = os.system('psql -q -p %d -h %s -U %s %s < %s > out 2> err' % (POSTGRESQL_PORT, POSTGRESQL_SERVER, POSTGRESQL_USERNAME, dbname, scriptfile[1]))

    # This little dance moves NOTICE: lines over from stderr to stdout
    os.system('grep ^NOTICE: err >> out; grep -v ^NOTICE: err >&2')
    os.system('cat out; rm out err')

    try:
        os.unlink(scriptfile[1])
    except OSError as e:
        pass

    return ret

def get_all_files_and_timestamp(webdav):
    dump_files_avilable = webdav.ls()

    all_the_files = []

    for f in dump_files_avilable:

        if not f.name or f.name[-1] == '/':
            continue

        # We try to extract a timestamp to get an idea of the creation date
        #  Format: Mon, 14 Mar 2016 03:31:40 GMT
        t = time.strptime(f.mtime, '%a, %d %b %Y %H:%M:%S %Z')

        # We don't take into consideration backups that are too recent.
        #  Otherwise they could be half uploaded (=> corrupted)
        dt = datetime.fromtimestamp(mktime(t))

        if abs((datetime.now() - dt).total_seconds()) < 900:
            print "SKIP", f.name, "(too recent)"
            continue

        all_the_files.append((dt, f))

    return all_the_files

def group_files_to_download(all_the_files):
    all_the_files.sort()
    all_the_files.reverse()
    import collections

    ret_files = collections.defaultdict(lambda : [])

    for a in all_the_files:
        t, f = a

        filepath = f.name

        if '/' not in filepath:
            continue

        isplit = filepath.rindex('/')
        filename = filepath[isplit+1:]

        if '-' not in filename:
            continue

        filename = '-'.join(filename.split('-')[:-1])

        ret_files[filename].append((filename, f))

    return ret_files

def fetch_webdav_file(webdav, f):

    # We have to download the file and restore it
    #  in another place
    destination_dir = '.'
    destination_zip_file = os.path.join(destination_dir, 'tmp.zip')

    try:
        os.unlink(destination_zip_file)
    except OSError as e:
        pass

    destf = open(destination_zip_file, 'wb')
    webdav.download(f.name, destf)
    destf.close()

    ## we open the zip file
    with ZipFile(destination_zip_file, 'r') as myzip:
        files = myzip.infolist()
        assert len(files) == 1
        zipfile = files[0]

        destination_dump_file = os.path.join(destination_dir, zipfile.filename)

        try:
            if os.path.isfile(destination_dump_file):
                os.unlink(destination_dump_file)
        except OSError as e:
            pass

        myzip.extract(zipfile, destination_dir)

    try:
        os.unlink(destination_zip_file)
    except OSError as e:
        pass

    return destination_dump_file

class RestoreFails(Exception):
    def __init__(self, message, dbname):
        self._message = message
        self._dbname = dbname

    def __str__(self):
        return self._message

    def dbname(self):
        return self._dbname

def restore_dump(filename, destination_dump_file):

    sql_file = 'create_db.sql'

    try:
        if os.path.isfile(sql_file):
            os.unlink(sql_file)
    except OSError as e:
        pass

    #TODO: Extract datetime from the filename
    #OCG_MZ1_CHA-20160315-140256-A-UF2.1-0p1.dump
    reg = re.compile('^(.*/)?(?P<dbname>[^-/]*)-\d{4}(?P<mois>\d{2})(?P<jour>\d{2})-(?P<heure>\d{2})(?P<minute>\d{2})\d{2}-.*$')
    m = reg.match(destination_dump_file)
    if m is None:
        dbname = filename
    else:
        gp = m.groupdict()
        dbname = '%s_%02d%02d_%02d%02d' % (gp['dbname'], int(gp['jour']), int(gp['mois']), int(gp['heure']), int(gp['minute']))

    ret = run_script('postgres', 'DROP DATABASE IF EXISTS "%s";' % dbname)
    if ret != 0:
        raise Exception("Cannot drop the database %s" % dbname)
    ret = run_script('postgres', 'CREATE DATABASE "%s";' % dbname)

    if ret != 0:
        raise Exception("Cannot create the new database %s" % dbname)

    # we try to remove the extension if it exists, it could cause pg_restore to return an exit code != 0
    run_script(dbname, 'DROP  LANGUAGE IF EXISTS plpgsql')

    ret = os.system('pg_restore -p %d -h %s -U %s --no-acl --no-owner -d %s %s' % (POSTGRESQL_PORT, POSTGRESQL_SERVER, POSTGRESQL_USERNAME, dbname, destination_dump_file))

    if ret != 0:
        raise RestoreFails("Bad dump file (%s)" % str(ret), dbname)

    try:
        os.unlink(destination_dump_file)
    except OSError as e:
        pass

    ret = run_script(dbname, "UPDATE ir_cron SET active = 'f' WHERE model = 'backup.config'")
    if ret != 0:
        raise RestoreFails("Cannot configure the backup file (%s)" % str(ret), dbname)
    ret = run_script(dbname, "UPDATE ir_cron SET active = 'f' WHERE model = 'sync.client.entity'")

    if ret != 0:
        raise RestoreFails("Cannot configure the backup file (%s)" % str(ret), dbname)

    return dbname

def download_and_restore_syncserver(db_name):
    url = "http://sync-prod_dump.uf5.unifield.org/SYNC_SERVER_LIGHT_WITH_MASTER"
    up = LOGIN_BACKUPS + ':' + PASSWORD_BACKUPS
    
    logging.info("Fetching dump from %s" % url)
    r = http.request('GET',
                     url,
                     headers=urllib3.util.make_headers(basic_auth=up),
                     preload_content=False)

    logging.info("Drop table.")
    ret = run_script("postgres", 'DROP DATABASE IF EXISTS "%s";' % db_name)
    if ret != 0:
        raise Exception("Cannot drop the database %s" % db_name)
    ret = run_script("postgres", 'CREATE DATABASE "%s";' % db_name)
    if ret != 0:
        raise Exception("Cannot create the database %s" % db_name)

    logging.info("SQL load.")
    os.environ['PGPASSWORD'] = POSTGRESQL_PASSWORD
    p = subprocess.Popen(['pg_restore',
                         '-p', str(POSTGRESQL_PORT),
                         '-h', POSTGRESQL_SERVER,
                         '-U', POSTGRESQL_USERNAME,
                         '-d', db_name,
                          '--no-acl', '--no-owner'],
                         stdin=subprocess.PIPE)
    bytes = 0
    for chunk in r.stream():
        bytes += len(chunk)
        p.stdin.write(chunk)
        if (bytes % (1024*1024) == 0):
            print "progress: %s bytes" % bytes

    print "progress: %s bytes (done)" % bytes
    p.stdin.close()
    ret = p.wait()
    if ret != 0:
        raise Exception("Non-zero result when loading the database: %s" % ret)

#
# main
#

DBNAME = 'SYNC_SERVER_XXX'
if match_any_wildcard(DBNAME):
    download_and_restore_syncserver(DBNAME)

webdav = easywebdav.connect('cloud.msf.org',
                            username=OWNCLOUD_USERNAME,
                            password=OWNCLOUD_PASSWORD,
                            protocol='https')
webdav.cd("remote.php")
webdav.cd("webdav")
webdav.cd(OWNCLOUD_DIRECTORY)

all_the_files = get_all_files_and_timestamp(webdav)
all_the_files = group_files_to_download(all_the_files)

for key, values in all_the_files.iteritems():
    if not values:
        continue

    if not match_any_wildcard(key):
        continue

    for filename, f in values:
        try:
            if not fnmatch.fnmatch(f.name, "*.zip"):
                logging.info("Skipping non-zip file %s" % f.name)
                continue

            print "Fetching %s (in %s)" % (filename, f.name)
            destination_dump_file = fetch_webdav_file(webdav, f)
            dbname = restore_dump(filename, destination_dump_file)

            # The values of the keys of all_the_files are in order
            # from newest to oldest. So stop processing once we have
            # restored the first file for this instance.
            break
        except RestoreFails as e:
            # RestoreFails means that we were unable to fix up the database
            # after loading it, so it would be bad to leave it. So drop the
            # DB if it still exists.
            run_script('postgres', 'DROP DATABASE IF EXISTS "%s"' % e.dbname())
            import traceback
            traceback.print_exc()
            logging.error(e)
        except Exception, e:
            # Something went wrong, leave the database in case it was
            # well enough loaded to be usable.
            import traceback
            traceback.print_exc()
            logging.error(e)

