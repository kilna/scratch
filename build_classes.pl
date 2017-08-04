#!/usr/bin/perl -w

my $infile = '/root/create_db.sql';
my $outdir = '/var/www/kilna/kilna.com/lib/Kilna';
my $prefix = 'Kilna';


open IN, '<', $infile || die;
local $/ = undef;
my $in = <IN>;
close IN;

$in =~ s|/\*.*\*/||gis;
$in =~ s|[ \t]+| |gis;
  
my $tables;

foreach my $command ( split /\s*;\s*/, $in ) {
	if ($command =~ m/^DROP TABLE /) {
	  next;
	}
	elsif ($command =~ m/^CREATE TABLE (\w+)\s+\(\s*(.*?)\s*\)$/s) {
		my $table = $1;
		my $spec = $2;
		foreach my $line (split /\s*,\s*\n\s*/, $spec) {
			if ($line =~ m/^PRIMARY KEY \(\s*(.*)\s*\)\s*$/s) {
				my $pks =  $1;
				push @{ $tables->{$table}{'pk'} }, split /\s*,\s*/, $pks;
			}
			elsif ($line =~ m/^UNIQUE \(\s*(.*)\s*\)\s*$/s) {
				my $uqs =  $1;
				push @{ $tables->{$table}{'uq'} }, split /\s*,\s*/, $uqs;
			}
			else {
				my ($col, $attrs) = split /\s+/, $line, 2;
				$attrs = " $attrs ";
				$attrs =~ s/ +/ /gis;
				my $not_null = $attrs =~ s/ NOT NULL / /gis;
				my $null = $attrs =~ s/ NULL / /gis;
				my $bin = $attrs =~ s/ BINARY / /gis;
				my $ai = 0;
				if ($attrs =~ s/ AUTO_INCREMENT / /gis) {
					$tables->{$table}{'ai'} = 1;
					$ai = 1;
				}
				my $type = '';
				my $size = '';
				if ($attrs =~ s/ INTEGER / /) {
					$type = 'integer';
					$size = 16;
				}
				if ($attrs =~ s/ BOOL / /) { $type = 'bool'; }
				if ($attrs =~ s/ DATETIME / /) { $type = 'datetime'; }
				if ($attrs =~ s/ MEDIUMTEXT / /) { $type = 'mediumtext'; }
				if ($attrs =~ m/ VARCHAR\s*\(\s*(\d+)\s*\) /) {
					$type = 'varchar';
					$size = $1;
					$attrs =~ s/ VARCHAR\s*\(\s*\d+\s*\) / /;
				}
				if ($attrs !~ m/\s+/) {
					die "Unknwon attribute in spec '$line'"
				}
				if ($type eq '') {
					die "Unknown type spec '$line' of table '$table'\n";
				}
				if ($not_null) { $null = 0; }
				push @{ $tables->{$table}{'order'} }, $col;
				$tables->{$table}{'cols'}{$col} = {
					size => $size,
					type => $type,
					null => $null,
					ai => $ai,
				};
			}
		}
	}
	elsif ($command =~ m/
		^
		ALTER \s+ TABLE \s+ (\w+) \s+
		ADD \s+ CONSTRAINT \s+ (\w+) \s+
		FOREIGN \s+ KEY \s* \( \s* ( .*) \s* \) \s+ 
		REFERENCES \s+ (\w+) \s* \( \s* (.*) \s* \)
		$
		/xs) {
		my $table = $1;
		my $constraint = $2;
		my $fk = $3;
		my $ref_table = $4;
		my $ref_pk = $5;
		$tables->{$table}{'has_many'}{$fk} = {
			'table' => $ref_table,
			'field' => $ref_pk,
		};
		push @{ $tables->{$ref_table}{'belongs_to'} }, $table;	
	}
	else {
		die "Unknown command '$command'";
	}
}

use Data::Dumper;
# print Dumper($tables);

foreach my $tbl (keys %{$tables}) {
	my %info = %{ $tables->{$tbl} };
	# print "\n$tbl\n";
    # print Dumper(\%info);
	my $pretty = prettify($tbl);
	my $classname = "$prefix\::$pretty";
	open CLS, '>', "$outdir/$pretty.pm" || die;
	print CLS "package $classname\n";
	print CLS "use base 'DBIx::Class';\n\n";
	my $components = "'Core'";
	if ($info{'ai'}) { $components .= ", 'PK::Auto'"; }
	print CLS "__PACKAGE__->load_components($components);\n";
	print CLS "__PACKAGE__->table('$tbl');\n";
	my $pks = "'" . join("', '", @{ $info{'pk'} }) . "'";
	print CLS "__PACKAGE__->set_primary_keys($pks);\n";
	print CLS "__PACKAGE__->add_columns(\n";
	foreach my $col ( @{ $info{'order' }} ) {
		my %c = %{$info{'cols'}{$col}};
		print CLS "  '$col' => {\n";
		print CLS "    type              => '$c{type}',\n";
		print CLS "    size              => '$c{size}',\n" if ($c{size} ne '');
		print CLS "    is_nullable       => $c{null}\n" if $c{null};
		print CLS "    is_auto_increment => $c{ai}\n" if $c{ai};
		print CLS "  },\n";
	}
	print CLS ");\n";
	foreach my $field ( keys %{ $info{'has_many'} } ) {
		my %r = %{ $info{'has_many'}{$field} };
		my $plural = "$r{table}s";
		my $ref_class = $prefix . '::' . prettify($r{table});
		print CLS "__PACKAGE__->has_many('$plural', '$ref_class', '$field');\n";
	}
	foreach my $ref_table ( @{ $info{'belongs_to'} } ) {
		my $ref_class = $prefix . '::' . prettify($ref_table);
		print CLS "__PACKAGE__->belongs_to('$ref_table', '$ref_class');\n";
	}
	print CLS "\n";
	print CLS "1;\n";
	close CLS;
}

sub prettify {
	return join '', map ucfirst, split '_', lc shift;
}
