package MooseX::Net::API::Role::Serialize;

use Moose::Role;
use JSON::XS;
use YAML::Syck;
use XML::Simple;
use Try::Tiny;

sub _to_json {
    return encode_json( $_[1] );
}

sub _to_yaml {
    return Dump $_[1];
}

sub _to_xml {
    my $xml = XML::Simple->new( ForceArray => 0 );
    $xml->XMLin("$_[0]");
}

sub _do_serialization {
    my ( $caller, $content, $format ) = @_;

    my $format_content;
    my $method = '_to_' . $format;
    return if ( !$caller->meta->find_method_by_name($method) );
    try {
        $format_content = $caller->$method($content);
    };
    return $format_content if $format_content;
}

1;
