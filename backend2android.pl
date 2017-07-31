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
$combineParams = "";

print "package $ARGV[1];\n";

open(FILE, "$ARGV[0]") or die $!;

while (<FILE>)
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
			$paramComment =~ s/^\s*\*\s*"(.*)"\s*:\s*#\s*(.*)/$1 $2/;
			$paramComment = " * \@param $paramComment";
			$inParamComments .= $paramComment;

			$param = $_;
			chomp($param);
			$param =~ s/^\s*\*\s*"(.*)"\s*:\s*#\s*.*/$1/;
			$inParamKeyValues .= "\"$param\":$param,";
			$combineParams .= "jsonObject.put(\"$param\", $param);\n";
			$param = "Object $param,";
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
			$outParamComments .= " * \t$paramComment";
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
		print "/**\n";
		print " * $title\n";
		print " * <p>\n";
		print " * <blockquote>\n";
		print " * <pre>\n";
		print " * {\n";
		print "$outParamComments\n";
		print " * }\n";
		print " * </pre>\n";
		print " * </blockquote>\n";
		print "$inParamComments";
		print " */\n";
		print "public static void $1($inParams Callback callback) {";
		if (!$inParamKeyValues) {
			$inParamKeyValues = ":";
		}
		print "\nJSONObject jsonObject = new JSONObject();\n";
		print "\n\ttry {\n";
		print "$combineParams\n";
		print "\t} catch (JSONException ex) {\n";
		print "\t\tex.printStackTrace();\n";
		print "\t}";
		print "\n\tHttpAgent.getInstance().post(\"$moduleName\/$1\", json, callback);";
		print "\n}\n\n";
		$inParamComments = "";
		$inParams = "";
		$outParamComments = "";
		$inParamKeyValues = "";
		$combineParams = "";
	}
}
print "}";
