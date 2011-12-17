package Ast;

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
			if($type eq 'if'){
				$item = shift @$parse_tree;
				$item = blend_if($item, $parse_tree);
			}
			elsif($type eq 'else'){
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
			if($type eq 'for_start'){
				$item = shift @$parse_tree;
				$item = blend_for($item, $parse_tree);
			}
			elsif($type eq 'for_else'){
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

1
