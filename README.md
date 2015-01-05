mediawiki-hana
==============

Command line app for browsing the MediaWiki API

## Installation and setup

Clone the git repository

```shell
$ git clone https://github.com/mkulumadzi/mediawiki-hana.git
```

Add the mediawiki-hana /bin directory to $PATH (for example, by editing .bashrc):

```shell
$ vim ./bashrc

export PATH="$PATH:$HOME/[path to mediawiki-hana]/bin"
```

## Usage

Get help

```shell
$ mediawiki-hana --help
```

Search for a page and output the default information to the terminal in plain-text format

```shell
$ mediawiki-hana 'foo' --text
```

Output the search string and titles only

```shell
$ mediawiki-hana 'foo' --text -st
```

Output to a csv file

```shell
$ mediawiki-hana 'foo' --csv -o output.csv
```

Get search terms from an input file and output results to a text file

```shell
$ mediawiki-hana -i input.csv --text -o output.txt
```