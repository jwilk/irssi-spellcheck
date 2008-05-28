#!/usr/bin/perl -w

# This script is a 5-minute-hack, so it's EXPERIMENTAL.
#
# Known bugs:
#  - won't catch all your mistakes
#  - works for public messages only
#  - all words will be marked and no suggestions given if 
#    dictionary is missing
#

use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use Text::Aspell;

$VERSION = '0.1';
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

sub spellcheck_check
{
    my ($lang, $msg) = @_;
    my $str = '';
    my $win = Irssi::active_win();

    # setup Text::Aspell for that lang if needed
    if (!exists $speller{$lang} || !defined $speller{$lang})
    {
	if (!spellcheck_setup($lang))
	{
	    $win->print("Error while setting up spellchecker for $lang");
	    # don't change the message
	    return $msg;
	}
    }

    # do the spellchecking
    foreach my $word (split(' ', $msg))
    {
	my ($stripped) = $word =~ /([^[:punct:][:digit:]]{2,})/; # at least 2 letters
	# Irssi::print("Debug: stripped $word is $stripped");
	if (!defined $stripped || $stripped =~ /^\d*$/ || $speller{$lang}->check($stripped))
	{
	    $str .= "$word ";
	}
	else
	{
	    my @suggestions = $speller{$lang}->suggest($stripped);
	    # poor man's underline ;-)
	    $str .= "_" . $word . "_ ";
	    if (Irssi::settings_get_bool('spellcheck_print_suggestions'))
	    {
		$win->print("Suggestions for $word - " . join(" ", @suggestions));
	    }
	}
    }

    return $str;
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

sub own_public
{ 
    my ($server, $message, $target) = @_;

    return unless Irssi::settings_get_bool('spellcheck_enabled');
    return unless (defined $server && defined $target && defined $message);

    my $lang = spellcheck_find_language($server->{tag}, $target);
    my $chk = spellcheck_check($lang, $message);

    # skip that signal magic if no spelling errors
    return if ($chk eq $message);

    Irssi::signal_stop();
    Irssi::signal_remove("message own_public", "own_public");
    Irssi::signal_emit("message own_public", $server, $chk, $target);
    Irssi::signal_add_first("message own_public", "own_public");
}

Irssi::settings_add_bool('spellcheck', 'spellcheck_enabled', 1);
Irssi::settings_add_bool('spellcheck', 'spellcheck_print_suggestions', 1);
Irssi::settings_add_str( 'spellcheck', 'spellcheck_default_language', 'en_US');
Irssi::settings_add_str( 'spellcheck', 'spellcheck_languages', '');

Irssi::signal_add_first("message own_public", "own_public");
