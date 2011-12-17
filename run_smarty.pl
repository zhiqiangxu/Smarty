#!/usr/bin/perl
use strict;
use warnings;
use Smarty;



my $smarty = Smarty->new('test.tmpl');
$smarty->assign('@loop', (1,2,3,4));
$smarty->assign('%loop2', (a => 'test', b => 'god'));
$smarty->output();
