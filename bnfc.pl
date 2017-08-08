#!/usr/bin/perl -w

$module = "";

print "package $ARGV[0].controller;\n\n";

open(FILE, "<$ARGV[1]") or die $!;

while (<FILE>) {
		if ($_ =~ /^\s*class\s*=\s*(\w+).*/) {
				$module = $1;
				print "import $ARGV[0].router.$module"."Router;\n\n";
				print "import spark.RouteGroup;\n\n";
				print "import static spark.Spark.post;\n\n";
				print "public class $module"."Controller {\n\n";
				print "\tpublic static RouteGroup routeGroup = () -> {\n";
		} elsif ($_ =~ /^\s*no\s*=(.*)/) {
				$function = "function$1";
				chomp($function);
				print "\t\tpost(\"/$function\", $module"."Router.$function);\n";
		}
}

print "\t};\n";
print "}";

close(FILE);


