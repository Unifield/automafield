# automafield

Our goal is to get rid of all the tedious work required to manage an environment made up of several databases that synchronize between each other.

A few commands are provided to manage these databases (restore, dump, synchronization, password reinitialization).

## How to install it

```
cd $HOME
git clone https://github.com/hectord/automafield.git
echo source $HOME/automafield/scripts.sh >> ~/.bashrc
```

Then you have to set up an environment where the code will be executed. You might have to upgrade your virtualenv before that:
```
pip install virtualenv --upgrade
```
Then
```
cd automafield
virtualenv myenv
source myenv/bin/activate
pip install -r requirements.txt
```


Then you have to edit $HOME/automafield/config.sh as follows:
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
