#!/usr/bin/perl -w

#$status = system("vi", "tmpfile");
#if ($status != 0) {
#	die "Fail to open tmpfile, $status, $!";
#}

#open(DATA, "<tmpfile") or die "ERROR，$!";

$no = "001";

$module = "";
$protocol = "";
$protoObject = "";
$findParams = 0;
$findReturn = 0;
$returnType = "";
@params = ();
$arrayName = "";
@spout = ();

$executed = "";

while (<>) {
	if ($_ =~ /^\s*class\s*=\s*(\w+).*/) {
		$module = $1;
	} elsif ($_ =~ /^\s*spout\s*=(.*)/) {
		$spout = $1;
		chomp($spout);
		while ($spout =~ /(\w+):(\w+),?/g) {
			push(@spout, "$1:$2");
		}
	} elsif ($_ =~ /^\s*proto\s*=\s*(\w+).*/) {
		$protocol = $1;
		if ($protocol eq "array") {
			$protoObject = "jerArray";
		} else {
			$protoObject = "jerObject";
		}
	} elsif ($_ =~ /^\s*title\s*=\s*(.*)/) {
		$title = $1;
		chomp($title);
		print "/**\n*";
		print "$title\n";
	} elsif ($_ =~ /^\s*params\s*=\s*\{.*/) {
		$findParams = 1;
		print "*<p>\n*请求\n";
		print "*<blockquote>\n*<pre>\n*\{\n";
	} elsif ($findParams == 1) {
		if ($_ =~ /^\s*(\w+):\s*(\w+):(.*)/) {
			$paramName = $1;
			$paramType = $2;
			$paramDes = $3;
			chomp($paramDes);
			if ($paramType eq "str") {
				print "*\"$paramName\":\t# $paramDes，字符串\n";
				push(@params, "$paramName:$paramType");
			} elsif ($paramType eq "num") {
				print "*\"$paramName\":\t# $paramDes，数字\n";
				push(@params, "$paramName:$paramType");
			}
		} elsif ($_ =~ /^\s*\}\s*$/) {
			$findParams = 0;
			print "*}\n";
			print "*</pre>\n";
			print "*</blockquote>\n";
		}
	} elsif ($_ =~ /^\s*return\s*=\s*([\{\[x]).*/) {
		$findReturn = 1;
		if ($1 eq "{") {
			print "* 返回对象结构\n";
			print "* <blockquote>\n";
			print "* <pre>\n";
			print "* {\n";
		} elsif ($1 eq "[") {
			print "* <blockquote>\n";
			print "* <pre>\n";
			print "* 返回数组结构\n";
			print "* {\n";
		} elsif ($1 eq "x") {
			print "* <blockquote>\n";
			print "* <pre>\n";
			print "* 返回 {\@code result} 为空\n";
			print "* </pre>\n";
			print "* </blockquote>\n";
			$findReturn = 0;
		}
	} elsif ($findReturn == 1) {
		if ($_ =~ /^\s*(\w+):\s*(\w+):(.*)/) {
			$paramName = $1;
			$paramType = $2;
			$paramDes = $3;
			chomp($paramDes);
			if ($paramType eq "str") {
				print "*\"$paramName\":\t# $paramDes，字符串\n";
			} elsif ($paramType eq "num") {
				print "*\"$paramName\":\t# $paramDes，数字\n";
			} elsif ($paramType eq "arr") {
				print "*\"$paramName\": [{\n";
				$returnType = "arr";
				$arrayName = $paramName;
				$executed .= "JSONArray items = new JSONArray();\n";
				$executed .= "while (resultSet.next()) {\n";
				$executed .= "JSONObject item = new JSONObject();\n";
			}
			if ($returnType ne "arr") {
				$executed .= "$protoObject\.getResult().put(\"$paramName\", $paramName);\n";
			} elsif ($paramType eq "num") {
				$executed .= "item.put(\"$paramName\", resultSet.getInt(\"".camel2pieces($paramName)."\"));\n";
			} elsif ($paramType eq "str") {
				$executed .= "item.put(\"$paramName\", resultSet.getString(\"".camel2pieces($paramName)."\"));\n";
			}
		} elsif ($_ =~ /^\s*\}\s*$/) {
			if ($returnType eq "arr") {
				$returnType = "";
				print "*}]\n";

				$executed .= "items.put(item);\n";
				$executed .= "}\n";
				$executed .= "$protoObject\.getResult().put(\"$arrayName\", items);\n";
			} else {
				$findReturn = 0;
				print "*}\n";
				print "*</pre>\n";
				print "*</blockquote>\n";
			}
		}
	} elsif ($_ =~ /^\s*end\s*$/) {
		print "*/\n";
		print "public static Route function$no = (Request req, Response res) -> {\n";

		if ($#params >= 0) {
			print "JSONObject body = new JSONObject(req.body());\n";

			foreach $param (@params) {
				$param =~ /(\w+):(\w+)/;
				$paramName = $1;
				$paramType = $2;
				if ($paramType eq "str") {
					print "String $paramName = body.optString(\"$paramName\");\n";
				} elsif ($paramType eq "num") {
					print "int $paramName = body.optInt(\"$paramName\");\n";
				}
			}
		}

		if ($protocol eq "object") {
			print "JERObject jerObject = new JERObject();\n";
		} elsif ($protocol eq "array") {
			print "JERArray jerArray = new JERArray();\n";
		}

		if ($#params >= 0) {
			print "Validator validator = new Validator();\n";

			print "if (!validator";

			foreach $param (@params) {
				$param =~ /(\w+):(\w+)/;
				$paramName = $1;
				$paramType = $2;
				if ($paramType eq "str") {
					print ".isNotNullOrEmptyAfterTrim($paramName, \"Invalid ".camel2pieces($paramName).".\")\n";
				} elsif ($paramType eq "num") {
					print ".isTrue($paramName >= 0, \"Invalid ".camel2pieces($paramName).".\")\n";
				}
			}

			print ".isPassed()) {\n";
			print "$protoObject.setError(1, validator.getErrorMessage());\n";
			print "return $protoObject.toString();\n";
			print "}\n";
		}

		print "ProcedureInvoker procedureInvoker = new ProcedureInvoker(Database.getDataSource());\n";
		print "procedureInvoker\.call(\"pro_$module\_function$no\",";

		if ($#params >= 0) {
			foreach $param (@params) {
				$param =~ /(\w+):\w+/;
				$paramName = $1;
				print $paramName.",";
			}
		}

		if ($#spout >= 0) {
			foreach $param (@params) {
				if ($param eq "str") {
					print "new OutParam(Types.VARCHAR),";
				} elsif ($param eq "num") {
					print "new OutParam(Types.INTEGER),";
				}
			}
		}

		print "new OutParam(Types.INTEGER));\n";
		print "procedureInvoker\.executed((resultSet, arrayList) -> {\n";

		$size = @spout;

		print "int ret = (int) arrayList.get($size);\n";
		print "switch (ret) {\n";
		print "case 0:\n";
		print "$protoObject\.setSuccess();\n"; 
		print "break;\n";
		print "default:\n";
		print "$protoObject\.setError(10 + ret, \"Unknown exception in database\");\n";
		print "break;\n";
		print "}\n";

		if ($#spout >= 0) {
			$i = 0;
			foreach $out (@spout) {
				$out =~ /(\w+):(\w+)/;
				$outType = $1;
				$outName = $2;
				if ($outType eq "num") {
					print "int $outName = (int)arrayList.get($i);\n";
				} elsif ($outType eq "str") {
					print "String $outName = arrayList.get($i).toString();\n";
				}
			}
		}

		print $executed;

		print "}).close();\n";

		print "if (procedureInvoker.isErrorOccured()) {\n";
		print "\t$protoObject\.setError(10, procedureInvoker.getErrorMessage());\n";
		print "}\n";

		print "return $protoObject\.toString();\n";
	}
}

print "};\n";

sub camel2pieces {

	$words = shift;
	$words =~ s/([A-Z])/\L $1\E/;
	return $words;

}

#close(DATA);
#status = system("rm", "-rf", "tmpfile");
