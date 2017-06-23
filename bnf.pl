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
		print "/**\n";
		print " * $title\n";
	} elsif ($_ =~ /^\s*params\s*=\s*\{.*/) {
		$findParams = 1;
		print " * <p>\n";
		print " * 请求\n";
		print " * <blockquote>\n";
		print " * <pre>\n";
		print " * \t\{\n";
	} elsif ($findParams == 1) {
		if ($_ =~ /^\s*(\w+):\s*(\w+):(.*)/) {
			$paramName = $1;
			$paramType = $2;
			$paramDes = $3;
			chomp($paramDes);
			if ($paramType eq "str") {
				print " * \t\t\"$paramName\":\t# $paramDes，字符串\n";
				push(@params, "$paramName:$paramType");
			} elsif ($paramType eq "num") {
				print " * \t\t\"$paramName\":\t# $paramDes，数字\n";
				push(@params, "$paramName:$paramType");
			}
		} elsif ($_ =~ /^\s*\}\s*$/) {
			$findParams = 0;
			print " * \t}\n";
			print " * </pre>\n";
			print " * </blockquote>\n";
		}
	} elsif ($_ =~ /^\s*return\s*=\s*([\{\[x]).*/) {
		$findReturn = 1;
		if ($1 eq "{") {
			print " * 返回对象结构\n";
			print " * <blockquote>\n";
			print " * <pre>\n";
			print " * \t{\n";
		} elsif ($1 eq "[") {
			print " * <blockquote>\n";
			print " * <pre>\n";
			print " * 返回数组结构\n";
			print " * \t{\n";
		} elsif ($1 eq "x") {
			print " * <blockquote>\n";
			print " * <pre>\n";
			print " * \t返回 {\@code result} 为空\n";
			print " * </pre>\n";
			print " * </blockquote>\n";
			$findReturn = 0;
		}
	} elsif ($findReturn == 1) {
		if ($_ =~ /^\s*(\w+):\s*(\w+):(.*)/) {
			$paramName = $1;
			$paramType = $2;
			$paramDes = $3;
			chomp($paramDes);
			if ($paramType eq "str") {
				if ($returnType ne "arr") {
					print " * \t\t\"$paramName\":\t# $paramDes，字符串\n";
				} else {
					print " * \t\t\t\"$paramName\":\t# $paramDes，字符串\n";
				}
			} elsif ($paramType eq "num") {
				if ($returnType ne "arr") {
					print " * \t\t\"$paramName\":\t# $paramDes，数字\n";
				} else {
					print " * \t\t\t\"$paramName\":\t# $paramDes，数字\n";
				}
			} elsif ($paramType eq "arr") {
				print " * \t\t\"$paramName\": [{\n";
				$returnType = "arr";
				$arrayName = $paramName;
				$executed .= "\t\tJSONArray items = new JSONArray();\n";
				$executed .= "\t\twhile (resultSet.next()) {\n";
				$executed .= "\t\t\tJSONObject item = new JSONObject();\n";
			}
			if ($returnType ne "arr") {
				$executed .= "\t\t$protoObject\.getResult().put(\"$paramName\", $paramName);\n";
			} elsif ($paramType eq "num") {
				$executed .= "\t\t\titem.put(\"$paramName\", resultSet.getInt(\"".camel2pieces($paramName)."\"));\n";
			} elsif ($paramType eq "str") {
				$executed .= "\t\t\titem.put(\"$paramName\", resultSet.getString(\"".camel2pieces($paramName)."\"));\n";
			}
		} elsif ($_ =~ /^\s*\}\s*$/) {
			if ($returnType eq "arr") {
				$returnType = "";
				print " * \t\t}]\n";

				$executed .= "\t\t\titems.put(item);\n";
				$executed .= "\t\t}\n";
				$executed .= "\t\t$protoObject\.getResult().put(\"$arrayName\", items);\n";
			} else {
				$findReturn = 0;
				print " * \t}\n";
				print " * </pre>\n";
				print " * </blockquote>\n";
			}
		}
	} elsif ($_ =~ /^\s*end\s*$/) {
		print " */\n";
		print "public static Route function$no = (Request req, Response res) -> {\n";

		if ($#params >= 0) {
			print "\tJSONObject body = new JSONObject(req.body());\n";

			foreach $param (@params) {
				$param =~ /(\w+):(\w+)/;
				$paramName = $1;
				$paramType = $2;
				if ($paramType eq "str") {
					print "\tString $paramName = body.optString(\"$paramName\");\n";
				} elsif ($paramType eq "num") {
					print "\tint $paramName = body.optInt(\"$paramName\");\n";
				}
			}

			print "\n";
		}

		if ($protocol eq "object") {
			print "\tJERObject jerObject = new JERObject();\n";
		} elsif ($protocol eq "array") {
			print "\tJERArray jerArray = new JERArray();\n";
		}

		if ($#params >= 0) {
			print "\tValidator validator = new Validator();\n";

			print "\tif (!validator";

			foreach $param (@params) {
				$param =~ /(\w+):(\w+)/;
				$paramName = $1;
				$paramType = $2;
				if ($paramType eq "str") {
					print ".isNotNullOrEmptyAfterTrim($paramName, \"Invalid ".camel2pieces($paramName).".\")\n\t\t";
				} elsif ($paramType eq "num") {
					print ".isTrue($paramName >= 0, \"Invalid ".camel2pieces($paramName).".\")\n\t\t";
				}
			}

			print ".isPassed()) {\n";
			print "\t\t$protoObject.setError(1, validator.getErrorMessage());\n";
			print "\t\treturn $protoObject.toString();\n";
			print "\t}\n\n";
		}

		print "\tProcedureInvoker procedureInvoker = new ProcedureInvoker(Database.getDataSource());\n";
		print "\tprocedureInvoker\.call(\"pro_$module\_function$no\",";

		if ($#params >= 0) {
			foreach $param (@params) {
				$param =~ /(\w+):\w+/;
				$paramName = $1;
				print $paramName.",";
			}
		}

		if ($#spout >= 0) {
			foreach $out (@spout) {
				$out =~ /(\w+):\w+/;
				$out = $1;
				if ($out eq "str") {
					print "new OutParam(Types.VARCHAR),";
				} elsif ($out eq "num") {
					print "new OutParam(Types.INTEGER),";
				}
			}
		}

		print "new OutParam(Types.INTEGER));\n";
		print "\tprocedureInvoker\.executed((resultSet, arrayList) -> {\n";

		$size = @spout;

		print "\t\tint ret = (int) arrayList.get($size);\n";
		print "\t\tswitch (ret) {\n";
		print "\t\t\tcase 0:\n";
		print "\t\t\t$protoObject\.setSuccess();\n"; 
		print "\t\t\tbreak;\n";
		print "\t\tdefault:\n";
		print "\t\t\t$protoObject\.setError(10 + ret, \"Unknown exception in database\");\n";
		print "\t\t\tbreak;\n";
		print "\t\t}\n";

		if ($#spout >= 0) {
			$i = 0;
			foreach $out (@spout) {
				if ($out =~ /(\w+):(\w+)/) {
					$outType = $1;
					$outName = $2;
					if ($outType eq "num") {
						print "\t\tint $outName = (int)arrayList.get($i);\n";
					} elsif ($outType eq "str") {
						print "\t\tString $outName = arrayList.get($i).toString();\n";
					}
				}
				$i = $i + 1;
			}
		}

		$executed .= "\t\t$protoObject\.setSuccess();\n";
		print $executed;

		print "\t}).close();\n\n";

		print "\tif (procedureInvoker.isErrorOccured()) {\n";
		print "\t\t$protoObject\.setError(10, procedureInvoker.getErrorMessage());\n";
		print "\t}\n\n";

		print "\treturn $protoObject\.toString();\n";
	}
}

print "};\n";

sub camel2pieces {

	$words = shift;
	$words =~ s/([A-Z])/\L $1\E/;
	return $words;

}

#close(DATA);
#$status = system("rm", "-rf", "tmpfile");
