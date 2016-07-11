# automafield

Our goal is to get rid of all the tedious work required to manage an environment made up of several databases that synchronize between each other.

A few commands are provided to manage these databases (restore, dump, synchronization, password reinitialization).

## How to install it

```
cd $HOME
git clone https://github.com/hectord/automafield.git
echo source $HOME/automafield/script.sh >> ~/.bashrc
cp automafield/config.s $HOME/.automafield.config.sh
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
* ENV4SYNC
* NORMALPORT
* MYPORT
* MY_LOGIN_OWNCLOUD
* MY_PASSWORD_OWNCLOUD
* MYHWID
* LOGIN_BACKUPS
* PASSWORD_BACKUPS
* URL_BACKUPS

## How to update it

```
cd $HOME
rm -rf automafield
git clone https://github.com/hectord/automafield.git
```

**Please do not update testfield if you're using it.**
