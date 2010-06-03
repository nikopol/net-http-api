package MooseX::Net::API::Role::Request;

use Moose::Role;
use HTTP::Request;
use MooseX::Net::API::Error;
use MooseX::Types::URI qw(Uri);

has api_base_url => (
    is      => 'rw',
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    default => sub {
        my $self         = shift;
        my $api_base_url = $self->meta->get_api_option('api_base_url');
        if (!$api_base_url) {
            die MooseX::Net::API::Error->new(
                reason => "'api_base_url' have not been defined");
        }
        $api_base_url;
    }
);

sub http_request {
    my ($self, $method, $uri, $params_in_url, $args) = @_;

    my $request;

    if ( $method =~ /^(?:GET|DELETE)$/ || $params_in_url ) {
        $uri->query_form(%$args);
        $request = HTTP::Request->new( $method => $uri );
    }
    elsif ( $method =~ /^(?:POST|PUT)$/ ) {
        $request = HTTP::Request->new( $method => $uri );
        my $content = $self->serialize($args);
        $request->content($content);
    }
    else {
        die MooseX::Net::API::Error->new(
            reason => "$method is not defined" );
    }

    $request->header(
        'Content-Type' => $self->content_type->{$self->api_format}->{value})
      if $self->api_format_mode eq 'content-type';

    # XXX lwp hook!
    my $result = $self->api_useragent->request($request);
    return $result;
}

1;
__END__

=head1 NAME

MooseX::Net::API::Role::Request

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<http_request>

=back

=head2 ATTRIBUTES

=over 4

=item B<api_base_url>

=back

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2009, 2010 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
