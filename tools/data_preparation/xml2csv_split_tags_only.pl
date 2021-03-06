#This script reads in XML data from StackOverflow and returns it in text format
#Output "title \t body", one line per post
#At this stage we ignore replies to the posts, outputting only the question

#Usage example: perl xml2csv.pl Posts.xml Posts.xml.csv

use warnings;
use strict;

use XML::Simple;    # use XML::Twig for big files
use HTML::Strip;

use List::MoreUtils qw/ uniq /;

use utf8;
use Text::Unidecode;    #translates unicode into ascii

my $minVoteCount = 3;   #minimum number of votes required to save an answer

sub transform;

if ( scalar(@ARGV) != 2 ) {
	print "usage: xml2csv.pl in_file_name out_file_name\n";
	exit;
}

#read XML file into memory
my $ref = XMLin( $ARGV[0] );

open( my $fid, ">" . $ARGV[1] )
  or die("Cannot open $ARGV[1] : $!\n");    #export to CSV

my $hs = HTML::Strip->new();
print $fid "create_ts\tid\ttags\n";         #header
foreach ( @{ $ref->{row} } ) {
	if ( $_->{PostTypeId} == "1" ) {        #if the post is the original question
		my $creationDate = ( $_->{CreationDate} );
		my $id           = $_->{Id};
		my $tags         = $_->{Tags};
		my $bestAnswerId = $_->{AcceptedAnswerId};

		#remove "<" and replace ">" with " "

		#$tags =~ s/></^&^/g;
		#$tags =~ s/^<//g;
		#$tags =~ s/>$//g;

		$tags = transform( $_->{Tags} );
		$tags =~ tr/ +/ /;                           #replace multiple spaces with a single one

		my @tmp = split / /, $tags;
		@tmp = grep !/^\d+$/, @tmp;                  #remove numeric "words"
		@tmp = uniq(@tmp);                           #keep only unique words

		$tags = join( "^&^", @tmp );

		print $fid join( "\t", ( $creationDate, $id, $tags ) ) . "\n";
	}
}
close $fid;
$hs->eof;

#convert unicode to ascii and make it lower case
sub transform {
	my ($txt) = @_;
	$txt =~ s/\n|\t/ /g;          #replace new line or tab with space
	$txt =~ s/[[:punct:]]/ /g;    #replace punctuation with space
	return lc( unidecode($txt) ); #convert #convert unicode to latin and change words to lowercase
}

