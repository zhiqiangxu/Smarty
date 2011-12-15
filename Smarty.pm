package Smarty;
use strict;
use warnings;
use Parse::RecDescent;
require "Eval.pl";

sub new {
	my ($class, $tmpl) = @_;
	my $grammar = _file_get_contents('html.grammar');
	my $parser = new Parse::RecDescent ($grammar);
	my $text = _file_get_contents($tmpl);
	my $parse_tree = $parser->spec($text) or print "Bad text!\n";
	my $self = {parse_tree => Eval::Blend($parse_tree), param => Smarty::Param->new};
	bless $self, $class;
	return $self;
}

package Smarty::Param;

sub new {
	my ($class, %v) = @_;
	my $self = {};
	bless $self, $class;
	while(my ($k, $v) = each(%v)){
		$self->set($k, ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? %$v : $v);
	}
	return $self;
}

sub set {
	my ($self, $name, @value) = @_;
	my $type = substr($name, 0, 1);
	if($type eq '$'){
		$self->{$name} = $value[-1];
	}
	elsif($type eq '@'){
		$self->{$name} = \@value;
	}
	elsif($type eq '%'){
		my %value = @value;
		$self->{$name} = \%value;
	}
}

sub push {
	my ($self, %values) = @_;
	return Smarty::Param->new(%values, __parent__ => $self);
}

sub get {
	my ($self, $name) = @_;
	my $type = substr($name, 0, 1);
	if($type eq '$'){
		return $self->{$name} || ($self->{__parent__} and $self->{__parent__}->get($name));
	}
	elsif($type eq '@'){
		return $self->{$name} ? @{$self->{$name}} : ($self->{__parent__} ? () : $self->{__parent__}->get($name));
	}
	elsif($type eq '%'){
		return $self->{$name} ? %{$self->{$name}} : ($self->{__parent__} ? () : $self->{__parent__}->get($name));
	}
}

package Smarty;

sub assign {
	my ($self, $name, @value) = @_;
	$self->{param}->set($name, @value);
}

sub _file_get_contents {
	my ($file) = @_;
	open FD, '<', $file;
	local $/;
	my $contents = <FD>;
	close FD;
	return $contents;
}

sub output {
	my ($self) = @_;
	for my $statement (@{$self->{parse_tree}}){
		Eval::Eval($statement, $self->{param});
	}
}

1