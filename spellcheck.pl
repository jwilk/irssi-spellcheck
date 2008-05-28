#!/usr/bin/perl -w

# This script is a 10-minutes-hack, so it's EXPERIMENTAL.
#
# Works as you type, printing suggestions when Aspell thinks
# your last word was misspelled.
#
# Known bugs:
#  - won't catch all mistakes
#  - works every time you press space or a dot (so won't work after
#    tabcompletions and obviously won't work for last word before
#    pressing enter unless you're using dot to finish your sentences)
#  - all words will be marked and no suggestions given if 
#    dictionary is missing (ie. wrong spellcheck_default_language)


use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use Text::Aspell;

$VERSION = '0.2';
%IRSSI = (
    authors     => 'Jakub Jankowski',
    contact     => 'shasta@toxcorp.com',
    name        => 'Spellcheck',
    description => 'Checks for spelling errors using Aspell.',
    license     => 'GPLv2',
    url         => 'http://toxcorp.com/irc/irssi/spellcheck/',
);

my %speller;

sub spellcheck_setup
{
    return if (exists $speller{$_[0]} && defined $speller{$_[0]});
    $speller{$_[0]} = Text::Aspell->new;
    return undef unless defined $speller{$_[0]};
    $speller{$_[0]}->set_option('lang', $_[0]);
    $speller{$_[0]}->set_option('sug-mode', 'fast');
    return $speller{$_[0]}->get_option('lang');
}

sub spellcheck_check_word
{
    my ($lang, $word) = @_;
    my $win = Irssi::active_win();
    my @suggestions = ();

    # setup Text::Aspell for that lang if needed
    if (!exists $speller{$lang} || !defined $speller{$lang})
    {
	if (!spellcheck_setup($lang))
	{
	    $win->print("Error while setting up spellchecker for $lang");
	    # don't change the message
	    return @suggestions;
	}
    }

    # do the spellchecking
    my ($stripped) = $word =~ /([^[:punct:][:digit:]]{2,})/; # HAX
    # Irssi::print("Debug: stripped $word is '$stripped' and lang is $lang");
    if (defined $stripped && !$speller{$lang}->check($stripped))
    {
        @suggestions = $speller{$lang}->suggest($stripped);
    }
    return @suggestions;
}

sub spellcheck_find_language
{
    my ($network, $target) = @_;
    return Irssi::settings_get_str('spellcheck_default_language') unless (defined $network && defined $target);

    # support !channels correctly
    $target = '!' . substr($target, 6) if ($target =~ /^\!/);

    # lowercase net/chan
    $network = lc($network);
    $target  = lc($target);

    # possible settings: network/channel/lang  or  channel/lang
    my @languages = split(/[ ,]/, Irssi::settings_get_str('spellcheck_languages'));
    for my $langstr (@languages)
    {
	# strip trailing slashes
	$langstr =~ s=/+$==;
	# Irssi::print("Debug: checking network $network target $target against langstr $langstr");
	my ($s1, $s2, $s3) = split(/\//, $langstr, 3);
	my ($t, $c, $l);
	if (defined $s3 && $s3 ne '')
	{
	    # network/channel/lang
	    $t = lc($s1); $c = lc($s2); $l = $s3;
	}
	else
	{
	    # channel/lang
	    $c = lc($s1); $l = $s2;
	}

	if ($c eq $target && (!defined $t || $t eq $network))
	{
	    # Irssi::print("Debug: language found: $l");
	    return $l;
	}
    }

    # Irssi::print("Debug: language not found, using default");
    # no match, use defaults
    return Irssi::settings_get_str('spellcheck_default_language');
}

sub spellcheck_key_pressed
{
    my ($key) = @_;
    my $win = Irssi::active_win();

    # it's impossible to modify the input line from perl
    # so there's no way to mark misspelled words.
    # that's why there's no spellcheck_print_suggestions anymore
    # because printing suggestions is our only choice.
    return unless Irssi::settings_get_bool('spellcheck_enabled');

    # don't bother unless pressed key is space
    return unless (chr $key eq ' ' or chr $key eq '.');

    # get current inputline
    my $inputline = Irssi::parse_special('$L');

    # check if inputline starts with any of cmdchars
    # we shouldn't spellcheck commands
    my $cmdchars = Irssi::settings_get_str('cmdchars');
    my $re = qr/^[$cmdchars]/;
    return if ($inputline =~ $re);

    # get last bit from the inputline
    my ($word) = $inputline =~ /\s*([^\s]+)$/;

    # find appropriate language for current window item
    my $lang = spellcheck_find_language($win->{active_server}->{tag}, $win->{active}->{name});

    my @suggestions = spellcheck_check_word($lang, $word);
    # Irssi::print("Debug: spellcheck_check_word($word) returned array of " . scalar @suggestions);
    return if (scalar @suggestions == 0);

    # we found a mistake, print suggestions
    $win->print("Suggestions for $word - " . join(", ", @suggestions));
}


Irssi::settings_add_bool('spellcheck', 'spellcheck_enabled', 1);
Irssi::settings_add_str( 'spellcheck', 'spellcheck_default_language', 'en_US');
Irssi::settings_add_str( 'spellcheck', 'spellcheck_languages', '');

Irssi::signal_add_first('gui key pressed', 'spellcheck_key_pressed');
