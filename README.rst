=======================
Spell-checker for Irssi
=======================

Requires
~~~~~~~~

* `Irssi`_ 0.8.12 or newer
* `GNU Aspell`_ with appropriate dictionaries
* Perl module `Text::Aspell`_

.. _Irssi:
   https://irssi.org/
.. _GNU Aspell:
   http://aspell.net/
.. _Text::Aspell:
   https://metacpan.org/release/Text-Aspell

Description
~~~~~~~~~~~
Works as you type, printing suggestions when Aspell thinks your last
word was misspelled. It also adds suggestions to the list of
tab-completions, so once you know last word is wrong, you can go back
and tab-complete through what Aspell suggests.

Settings
~~~~~~~~

* ``spellcheck_languages`` — a list of space or comma separated
  languages to use on certain networks/channels. Example: ``/set
  spellcheck_languages netA/#chan1/en_US,#chan2/fi_FI,
  netB/!chan3/pl_PL`` will use ``en_US`` for ``#chan1`` on network
  ``netA``, ``fi_FI`` for ``#chan2`` on every network, and ``pl_PL`` for
  ``!chan3`` on network ``netB``.
  You can use ``und`` as language code to disable spellchecking.
  By default this setting is empty.
* ``spellcheck_default_language`` — language to use in empty windows,
  or when nothing from ``spellcheck_languages`` matches. Defaults to
  ``en_US``.
* ``spellcheck_enabled`` [``ON``/``OFF``] — self explaining. Sometimes
  (like when pasting foreign-language text) you don't want the script to
  spit out lots of suggestions, and turning it off for a while is the
  easiest way. By default it's ``ON``.
* ``spellcheck_word_color`` — highlight misspelled word to this color.

Corrections in a split window
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
As an experimental feature, it is possible to display corrections in a
separate split window:

* ``spellcheck_window_name`` - name of the window.
* ``spellcheck_window_height`` - height of the window.

It's user's responsibility to create the window::

   /WINDOW NEW SPLIT
   /WINDOW NAME <name>
   /WINDOW STICK OFF
   /WINDOW HIDE

Commands
~~~~~~~~
* ``/SPELLCHECK_ADD <word>...`` - add word(s) to personal dictionary.

Bugs
~~~~

* It won't catch all mistakes.
* Picking actual words from what you type is very kludgy, you may
  occasionally see some leftovers like digits or punctuation
* Works every time you press space or a dot (so won't work for the last
  word before pressing enter, unless you're using dot to finish your
  sentences).
* When you press space and realize that the word is wrong, you can't
  tab-complete to the suggestions right away - you need to use backspace
  and then tab-complete. With dot you get an extra space after
  tab-completion.
* Probably more, please report to `Jakub Wilk <jwilk@jwilk.net>`_.

.. vim:ts=3 sts=3 sw=3 et tw=72
