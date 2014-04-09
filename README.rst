Semi-fancy bash prompt
**********************

Byron Peebles, based on https://gist.github.com/insin/1425703

Changes from that are:

 * single line prompt
 * speed up git repo detection
 * rejigger some of the verbage and how it decides about git up/down status.

Description
===========

Set the bash prompt according to:

* the active virtualenv
* the branch/status of the current git repository
* the return value of the previous command

Usage
=====

1. Save the ``bash_prompt.sh`` file as ``~/.bash_prompt`` (or symlink to it)
2. Add the following line to the end of your ``~/.bash_aliases``, ``~/.bashrc``
   or ``~/.bash_profile`` depending on your preference::

   . ~/.bash_prompt

Lineage
=======

Based on work by woods: https://gist.github.com/31967
