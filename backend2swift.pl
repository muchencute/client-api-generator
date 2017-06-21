#!/usr/bin/perl -w

$comment = "";
$findTitle = 0;
$title = "";
$findInParams = 0;
$findOutParams = 0;
$inParamComments = "";
$inParams = "";
$outParamComments = "";
$isArray = 0;

while (<>)
{
	if ($_ =~ /^\s*\/\*{2,}/) {
		$comment = "";
		$findTitle = 1;
	} elsif ($findTitle == 1) {
		$title = $_;
		chomp($title);
		$title =~ s/^\s*\*\s*(.*)/$1/;
		$findTitle = 0;
	} elsif ($findInParams == 1) {
		if ($_ =~ /^\s*\*\s*".*"\s*:\s*#\s*.*/) {
			$paramComment = $_;
			$paramComment =~ s/^\s*\*\s*"(.*)"\s*:\s*#\s*(.*)/$1:$2/;
			$paramComment = "/// - parameter $paramComment";
			$inParamComments .= $paramComment;

			$param = $_;
			chomp($param);
			$param =~ s/^\s*\*\s*"(.*)"\s*:\s*#\s*.*/$1/;
			$param = "$param:Any,";
			$inParams .= $param;
		} elsif ($_ =~ /\*\//) {
			$findInParams = 0;
		} elsif ($_ =~ /\*\s*返回数组结构/) {
			$findInParams = 0;
			$findOutParams = 1;
		} elsif ($_ =~ /\*\s*返回对象结构/) {
			$findInParams = 0;
			$findOutParams = 1;
		}
	} elsif ($findOutParams == 1) {
		if ($_ =~ /^\s*\*\s*".*"\s*:\s*#\s*.*/) {
			$paramComment = $_;
			$paramComment =~ s/^\s*\*\s*(".*"\s*:\s*#\s*.*)/$1/;
			$outParamComments .= "/// $paramComment";
		} elsif ($_ =~ /\*\//) {
			$findOutParams = 0;
		}
	} elsif ($_ =~ /\*\s*请求/) {
		$findInParams = 1;
	} elsif ($_ =~ /\*\s*返回数组结构/) {
		$isArray = 1;
		$findOutParams = 1;
	} elsif ($_ =~ /\*\s*返回对象结构/) {
		$isArray = 0;
		$findOutParams = 1;
	} elsif ($_ =~ /Route.*(function\d{3})/) {
		chop($inParams);
		chomp($outParamComments);
		print "/// $title\n";
		print "/// ```\n";
		print "/// {\n";
		print "$outParamComments";
		print "\n/// }\n";
		print "/// ```";
		print "\n$inParamComments";
		print "func $1($inParams) {}\n\n";
		$inParamComments = "";
		$inParams = "";
		$outParamComments = "";
	}
}
