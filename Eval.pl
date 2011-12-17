package Eval;
use strict;
use warnings;
use Data::Dumper;



sub Eval {
	my ($parse_tree, $att) = @_;
	my $type = $parse_tree->[0];
	if($type eq 'code'){
		return eval_code($parse_tree, $att);
	}
	elsif($type eq 'literal'){
		return eval_literal($parse_tree);
	}
	else{
		warn "WARN: Unknown statement type: $type\n";
	}
}


sub Blend {
	my ($parse_tree) = @_;
	my @result;
	my $item;
	my $code;
	my $flag;
	while(1){
		if(0 == @$parse_tree){
			last;
		}
		$flag = 0;
		$item = shift @$parse_tree;
		if($item->[0] eq 'code'){
			$code = $item->[1];
			if($code->[0] eq 'if'){
				$flag = 1;
				push @result, blend_if($item, $parse_tree);
			}
			elsif($code->[0] eq 'for_start'){
				$flag = 1;
				push @result, blend_for($item, $parse_tree);
			}
		}
		
		push @result, $item unless $flag;
		
	}
	return \@result;
}

sub blend_if {
	my ($item, $parse_tree) = @_;
	my $consequent = blend_if_consequent($parse_tree);
	my $alternative = blend_if_alternative($parse_tree);
	push @$item, $consequent, $alternative;
	return $item;
}

sub blend_if_consequent {
	my ($parse_tree) = @_;
	my @consequent;
	my $type;
	while(@$parse_tree){
		my $item = $parse_tree->[0];
		$type = $item->[0];
		if($type eq 'code'){
			$type = $item->[1][0];
			if($type eq 'if'){
				$item = shift @$parse_tree;
				$item = blend_if($item, $parse_tree);
			}
			elsif($type eq 'else'){
				last;
			}
			elsif($type eq 'elsif'){
				last;
			}
			elsif($type eq 'if_end'){
				last;
			}
			else{
				$item = shift @$parse_tree;
			}
		}
		else{
			$item = shift @$parse_tree;
		}
		push @consequent, $item;
	}
	return \@consequent;
}

sub blend_for_consequent {
	my ($parse_tree) = @_;
	my @consequent;
	my $type;
	while(@$parse_tree){
		my $item = $parse_tree->[0];
		$type = $item->[0];
		if($type eq 'code'){
			$type = $item->[1][0];
			if($type eq 'for_start'){
				$item = shift @$parse_tree;
				$item = blend_for($item, $parse_tree);
			}
			elsif($type eq 'for_else'){
				last;
			}
			elsif($type eq 'for_end'){
				last;
			}
			else{
				$item = shift @$parse_tree;
			}
		}
		else{
			$item = shift @$parse_tree;
		}
		push @consequent, $item;
	}
	return \@consequent;
}

sub blend_if_alternative {
	my ($parse_tree) = @_;
	my @alternative;
	my $type;
	while(@$parse_tree){
		my $item = $parse_tree->[0];
		$type = $item->[0];
		if($type eq 'code'){
			$type = $item->[1][0];
			if($type eq 'else'){
				shift @$parse_tree;
				next;
			}
			elsif($type eq 'elsif'){
				$item = shift @$parse_tree;
				$item = blend_if($item, $parse_tree);
				$item->[0] = 'if';
				last;
			}
			elsif($type eq 'if_end'){
				shift @$parse_tree;
				last;
			}
			else{
				$item = shift @$parse_tree;
			}
		}
		else{
			$item = shift @$parse_tree;
		}
		push @alternative, $item;
	}
	return \@alternative;
}

sub blend_for_alternative {
	my ($parse_tree) = @_;
	my @alternative;
	my $type;
	while(@$parse_tree){
		my $item = $parse_tree->[0];
		$type = $item->[0];
		if($type eq 'code'){
			$type = $item->[1][0];
			if($type eq 'for_else'){
				shift @$parse_tree;
				next;
			}
			elsif($type eq 'for_end'){
				shift @$parse_tree;
				last;
			}
			else{
				$item = shift @$parse_tree;
			}
		}
		else{
			$item = shift @$parse_tree;
		}
		push @alternative, $item;
	}
	return \@alternative;
}

sub blend_for {
	my ($item, $parse_tree) = @_;
	my $consequent = blend_for_consequent($parse_tree);
	my $alternative = blend_for_alternative($parse_tree);
	push @$item, $consequent, $alternative;
	return $item;
}

sub eval_literal {
	my ($parse_tree) = @_;
	my $literal = $parse_tree->[1];
	print $literal;
}

sub eval_code {
	my ($parse_tree, $att) = @_;
	my $code = $parse_tree->[1];
	my $type = $code->[0];
	if($type eq 'if'){
		eval_if($parse_tree, $att);
	}
	elsif($type eq 'for_start'){
		eval_for($parse_tree, $att);
	}
	elsif($type eq 'term' or $type eq 'op'){
		print eval_exp($code, $att);
	}
}

sub eval_if {
	my ($parse_tree, $att) = @_;
	my (undef, $cond, $consequent, $alternative) = @{$parse_tree};
	$cond = $cond->[1];
	if(eval_exp($cond, $att)){
		map {Eval($_, $att)} @$consequent;
	}
	else{
		map {Eval($_, $att)} @$alternative;
	}
}

sub expand_att {
	my ($loop_attributes) = @_;
	my %h;
	for my $loop_att (@{$loop_attributes->[1]}){
		$h{$loop_att->[1]} = $loop_att->[2];
	}
	return ($h{from}, ($h{key} ? (join '', @{$h{key}[1]}[0,1]) : undef), ($h{value} ? (join '', @{$h{value}[1]}[0,1]) : undef));
}

sub eval_for_loop {
	my ($from, $k, $v, $att, $consequent, $alternative) = @_;
	my $from_value = eval_exp($from, $att, 1);
	if($from_value){
		if(ref $from_value eq 'ARRAY'){
			my $i = 0;
			for my $row (@$from_value){
				my $new_att = $att->push(defined $k ? ($k => $i) : (), defined $v ? ($v => $row) : ());
				map {Eval($_, $new_att)} @$consequent;
				$i++;
			}
		}
		elsif(ref $from_value eq 'HASH'){
			while(my ($kh, $vh) = each(%$from_value)){
				my $new_att = $att->push(defined $k ? ($k => $kh) : (), defined $v ? ($v => $vh) : ());
				map {Eval($_, $new_att)} @$consequent;
			}
		}
	}
	else{
		map {Eval($_, $att)} @$alternative;
	}
}

sub eval_for {
	my ($parse_tree, $att) = @_;
	my (undef, $loop_attributes, $consequent, $alternative) = @{$parse_tree};
	my ($from, $k, $v) = expand_att($loop_attributes);
	eval_for_loop($from, $k, $v, $att, $consequent, $alternative);
}

sub eval_exp {
	my ($exp, $att, $scalar) = @_;
	my $type = $exp->[0];
	if($type eq 'term'){
		eval_term($exp, $att, $scalar);
	}
	elsif($type eq 'op'){
		eval_op($exp, $att, $scalar);
	}
}

sub eval_term {
	my ($exp, $att, $scalar) = @_;
	my (undef, $term) = @$exp;
	my $type = $term->[0];
	if($type eq 'constant'){
		return $term->[1];
	}
	elsif($type eq '@'){
		return $att->get('@' . $term->[1], $scalar);
	}
    elsif($type eq '%'){
        return $att->get('%' . $term->[1], $scalar);
    }
	elsif($type eq '$'){
		if($term->[2] and @{$term->[2]}){
			my $type;
			my $a;
			for my $subscript (@{$term->[2]}){
				$type = $subscript->[1];
				if($type eq '['){
					$a = [$att->get('@' . $term->[1])] unless(defined $a);
					$a = $a->[eval_exp($subscript->[2])];
				}
				elsif($type eq '->['){
				}
			}
			return $a;
		}
		else{
			return $att->get('$' . $term->[1]);
		}
	}
}

sub eval_op {
	my ($parse_tree, $att, $scalar) = @_;
	my (undef, $operator, @operand) = @$parse_tree;
	if($operator eq 'or'){
		my $next;
		$next = eval_exp(shift @operand, $att, $scalar);
		return $next ? $next : eval_exp(shift @operand, $att, $scalar);
	}
	elsif($operator eq 'and'){
		return eval_exp(shift @operand, $att, $scalar) and eval_exp(shift @operand, $att, $scalar);
	}
}

1
