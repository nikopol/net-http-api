package MooseX::Net::API::Role::Deserialize;

use Moose::Role;
use JSON::XS;
use YAML::Syck;
use XML::Simple;
use Try::Tiny;

my $reverse_content_type = {
    'application/json'   => 'json',
    'application/x-yaml' => 'yaml',
    'text/xml'           => 'xml',
    'application/xml'    => 'xml',
};

sub _from_json {
    return decode_json( $_[1] );
}

sub _from_yaml {
    return Load $_[1];
}

sub _from_xml {
    my $xml = XML::Simple->new( ForceArray => 0 );
    $xml->XMLin( $_[1] );
}

sub _do_deserialization {
    my ( $caller, $raw_content, @content_types ) = @_;

    my $content;
    foreach my $deserializer (@content_types) {
        my $method;
        if ( $reverse_content_type->{$deserializer} ) {
            $method = '_from_' . $reverse_content_type->{$deserializer};
        }
        else {
            $method = '_from_' . $deserializer;
        }
        next if ( !$caller->meta->find_method_by_name($method) );
        try {
            $content = $caller->$method($raw_content);
        };
        return $content if $content;
    }
}

1;
