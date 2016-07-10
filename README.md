# automafield

Our goal is to get rid of all the tedious work required to manage an environment made up of several databases that synchronize between each other.

A few commands are provided to manage these databases (restore, dump, synchronization, password reinitialization).

## How to install it

```
cd $HOME
git clone https://github.com/hectord/automafield.git
echo source $HOME/automafield/scripts.sh >> ~/.bashrc
```

## How to update it

```
cd $HOME
rm -rf automafield
git clone https://github.com/hectord/automafield.git
```
