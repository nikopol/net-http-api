package MooseX::Net::API::Role::Format;

use Moose::Role;
use Moose::Util::TypeConstraints;

sub content_type {
    {   json => {value => 'application/json', module => 'JSON',},
        yaml => {value => 'text/x-yaml',      module => 'YAML'},
        xml  => {value => 'text/xml',         module => 'XML::Simple'},
    };
}

subtype Format => as 'Str' => where {
    my $format = shift;
    grep {/^$format$/} keys %{content_type()};
};

enum 'FormatMode' => qw(content-type append);

has api_format => (
    is      => 'rw',
    isa     => 'Format',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->meta->get_option('api_format');
    }
);

has api_format_mode => (
    is      => 'rw',
    isa     => 'FormatMode',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $mode = $self->meta->get_option('api_format_mode');
        $mode || 'append';
    }
);

1;
