use XML::LibXSLT;
use XML::LibXML;

my $XML_FILENAME = shift @ARGV;
my $XSL_FILENAME = "lfet.xsl";
my $OUTPUT_FILENAME = shift @ARGV;

my $xml_parser  = XML::LibXML->new;
my $xslt_parser = XML::LibXSLT->new;

my $xml         = $xml_parser->parse_file($XML_FILENAME);
my $xsl         = $xml_parser->parse_file($XSL_FILENAME);

my $stylesheet  = $xslt_parser->parse_stylesheet($xsl);
my $results     = $stylesheet->transform($xml);
my $output      = $stylesheet->output_string($results);

# the main command and of course the easiest one
$stylesheet->output_file($results, $OUTPUT_FILENAME);
