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
$moduleName = "";
$inParamKeyValues = "";

print "import Foundation\n";
print "import Alamofire\n\n";

while (<>)
{
	if ($_ =~ /^\s*[a-z\s]*class\s*(\w+)Router/) {
		$moduleName = $_;
		chomp($moduleName);
		$moduleName =~ s/.*class\s(\w+)Router.*/$1/;
		print "class $moduleName : AbstractRequest {\n\n";
		$moduleName =~ s/(.*)/\L$1\E/;
	} elsif ($_ =~ /^\s*\/\*{2,}/) {
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
			$inParamKeyValues .= "\"$param\":$param,";
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
		chomp($outParamComments);
		chop($inParamKeyValues);
		print "/// $title\n";
		print "/// ```\n";
		print "/// {\n";
		print "$outParamComments";
		print "\n/// }\n";
		print "/// ```";
		print "\n$inParamComments";
		print "func $1($inParams callback: \@escaping (DataResponse<Any>) -> Void) {";
		if (!$inParamKeyValues) {
			$inParamKeyValues = ":";
		}
		print "\tpost(url:\"$moduleName\/$1\", params:[$inParamKeyValues], callback: callback)";
		print "}\n\n";
		$inParamComments = "";
		$inParams = "";
		$outParamComments = "";
		$inParamKeyValues = "";
	}
}
print "}";
