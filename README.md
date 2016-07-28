# automafield

Our goal is to get rid of all the tedious work required to manage an environment made up of several databases that synchronize between each other.

A few commands are provided to manage these databases (restore, dump, synchronization, password reinitialization).

## How to install it

Before installing automafield itself and building the Python environment for it, you need the following tools:
* git
* python-pip
* postgresql-server-dev-all postgresql-client
* libjpeg-dev

You can use the package management system from your linux distribution.

```
cd $HOME
git clone --recursive https://github.com/hectord/automafield.git
echo source $HOME/automafield/script.sh >> ~/.bashrc
cp automafield/config.sh $HOME/.automafield.config.sh
```

Then you have to set up an environment where the code will be executed. You might have to upgrade your virtualenv before that:
```
pip install virtualenv --upgrade
```
Then:
```
cd $HOME
virtualenv myenv_automafield
source myenv_automafield/bin/activate
cd automafield
pip install -r requirements.txt
```

Then you have to edit $HOME/.automafield.config.sh as follows:
* **ENV4SYNC**: the python environment in which you've installed all the libraries (it's located in $HOME/myenv_automafield/bin/activate according to the procedure above)
* **NORMALPORT**: the PostgreSQL port in use (most of the time: 5432)
* **MYPORT**: the PostgreSQL port in use on your own computer (most of the time: 5432)
* **MY_LOGIN_OWNCLOUD**: your login on OwnCloud
* **MY_PASSWORD_OWNCLOUD**: your password on OwnCloud
* **MYHWID**: you instance's hardware ID
* **URL_BACKUPS**: the URL where we can fetch the last version of the SYNC_SERVER (SCP)
* **LOGIN_BACKUPS**: the login we use to fetch the backup
* **PASSWORD_BACKUPS**: the password we use to fetch the backup
* **POSTGRES_USERNAME**: the PostgreSQL's username to connect to other database
* **POSTGRES_PASSWORD**: the PostgreSQL's password to connect to other database
* **MY_POSTGRES_USERNAME**: your PostgreSQL's username to connect to your database (0 and 10)
* **MY_POSTGRES_PASSWORD**: your PostgreSQL's password to connect to your database (0 and 10)

Having done that, you have to set the IP address of your instances. They all have to start with "ct". You can do that in your host file (`/etc/hosts`) like that:
```
127.0.0.1 ct0
192.168.1.1 ct1 
192.168.1.2 ct2 
```

We set ct0 as the localhost by convention.

## How to update it

```
cd $HOME
rm -rf automafield
git clone --recursive https://github.com/hectord/automafield.git
source myenv_automafield/bin/activate
cd automafield
pip install -r requirements.txt
```

**Please do not update testfield if you're using it.**
