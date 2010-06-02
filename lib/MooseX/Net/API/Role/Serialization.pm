package MooseX::Net::API::Role::Serialization;

use Try::Tiny;
use Moose::Role;

has serializers => (
    traits     => ['Hash'],
    is         => 'rw',
    isa        => 'HashRef[MooseX::Net::API::Parser]',
    default    => sub { {} },
    auto_deref => 1,
    handles    => {
        _add_serializer => 'set',
        _get_serializer => 'get',
    },
);

sub deserialize {
    my ($self, $content, $list_of_formats) = @_;

    foreach my $format (@$list_of_formats) {
        my $s = $self->_get_serializer($format)
          || $self->_load_serializer($format);
        next unless $s;
        my $result = try { $s->decode($content) };
        return $result if $result;
    }
}

sub serialize {
    my ($self, $content) = @_;
    my $s = $self->_get_serializer($self->api_format);
    my $result = try { $s->encode($content) };
    return $result if $result;
}

sub _load_serializer {
    my $self   = shift;
    my $format = shift || $self->api_format;
    my $parser = "MooseX::Net::API::Parser::" . uc($format);
    if (Class::MOP::load_class($parser)) {
        my $o = $parser->new;
        $self->_add_serializer($format => $o);
        return $o;
    }
}

1;
