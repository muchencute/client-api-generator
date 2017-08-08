#!/usr/bin/perl -w

use DBI;
use POSIX;

$schema="";
$host="";
$port="3306";
$username="root";
$password="";

@tables=();

@characters=('a'..'z', 'A'..'Z');

while(<>) {

	if ($_ =~ /^\s*host\s*=\s*([A-Za-z0-9_.]+)\s*$/) {
		$host = $1;
	} elsif ($_ =~ /^\s*port\s*=\s*(\d+)\s*$/) {
		$port = $1;
	} elsif ($_ =~ /^\s*username\s*=\s*(\w+)\s*$/) {
		$username = $1;
	} elsif ($_ =~ /^\s*password\s*=\s*(\w+)\s*$/) {
		$password = $1;
	} elsif ($_ =~ /^\s*schema\s*=\s*(\w+)\s*$/) {
		$schema = $1;
	} elsif ($_ =~ /^\s*table\s*=\s*([\w\d_]+)\s*$/) {
		push @tables, $1;
	}
}

print "-- host=$host\n";
print "-- schema=$schema\n";
print "-- port=$port\n";
print "-- username=$username\n";
print "-- password=$password\n";

$dsn = "DBI:mysql:database=information_schema;host=$host;port=$port";

$dbh = DBI->connect($dsn, $username, $password, {'RaiseError' => 1});

print "use $schema;\n\n";

foreach my $table (@tables) {
	print "-- $table\n";
	print "truncate table `$table`;\n\n";
	generate($table);
	print "\n\n";
}

$dbh->disconnect();

sub generate {
	my $table = shift;
	$sth = $dbh->prepare("SELECT * FROM COLUMNS WHERE TABLE_SCHEMA = '$schema' AND TABLE_NAME = '$table'");
	$sth->execute();
	my @values = ();
	my $sql = "INSERT INTO `$table` (";
	while (my $ref = $sth->fetchrow_hashref()) {
		if ($ref->{'COLUMN_KEY'} ne 'PRI') {
			$sql .= "`$ref->{'COLUMN_NAME'}`,";
			push @values, $ref->{'DATA_TYPE'};
		}
	}
	$sth->finish();

	chop($sql);
	$sql .= ") VALUES (";

	for (1..100) {
		my $newSql = $sql;
		foreach $value (@values) {
			if ($value eq 'int') {
				$newSql .= int(rand(100)).",";
			} elsif ($value eq 'varchar') {
				$newSql .= "'".randText(2)."',";
			} elsif ($value eq 'text') {
				$newSql .= "'".randText(10)."',";
			} elsif ($value eq 'datetime') {
				my $date = strftime "%Y-%m-%d", localtime(time-86400*(int(rand(365))));
				$newSql .= "'".$date."',";
			}
		}
		chop($newSql);
		$newSql .= ");\n";
		print $newSql;
	}
}

sub randWord {
	my $word = join '', map { $characters[int rand @characters] } 1..int(rand(10)), "\n";
	$word =~ s/(\w)(\w+)/\U$1\E\L$2\E/;
	return $word;
}

sub randText {
	my $wordCount = shift;
	my $text = '';
	for (1..$wordCount) {
		$text .= randWord." ";
	}
	return $text.".";
}
