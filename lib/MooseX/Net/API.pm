package MooseX::Net::API;

use URI;
use Carp;
use Try::Tiny;
use HTTP::Request;

use Moose;
use Moose::Exporter;
use MooseX::Net::API::Error;
use MooseX::Net::API::Meta::Class;
use MooseX::Net::API::Meta::Method;
with qw/
    MooseX::Net::API::Role::Serialize 
    MooseX::Net::API::Role::Deserialize/;

our $VERSION = '0.03';

my $list_content_type = {
    'json' => 'application/json',
    'yaml' => 'text/x-yaml',
    'xml'  => 'text/xml',
};

# XXX uri builder
# XXX encoding
# XXX decoding

Moose::Exporter->setup_import_methods(
    with_caller => [qw/net_api_method net_api_declare/], );

sub init_meta {
    my ( $me, %options ) = @_;

    my $for = $options{for_class};
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => $for,
        metaclass_roles => ['MooseX::Net::API::Meta::Class'],
    );
}

my ( $do_auth, $auth_method, $deserialize_method );

sub net_api_declare {
    my $caller  = shift;
    my $name    = shift;
    my %options = @_;

    my $class = Moose::Meta::Class->initialize($caller);

    $class->add_attribute(
        'api_base_url',
        is      => 'rw',
        isa     => 'Str',
        lazy    => 1,
        default => delete $options{base_url} || '',
    );

    if ( !$options{format} ) {
        croak "format is missing in your api declaration";
    }
    elsif ( !$list_content_type->{ $options{format} } ) {
        croak "format is not recognised. It must be "
            . join( " or ", keys %$list_content_type );
    }
    else {
        $class->add_attribute(
            'api_format',
            is      => 'ro',
            isa     => 'Str',
            lazy    => 1,
            default => delete $options{format}
        );
    }

    if ( !$options{format_mode} ) {
        croak "format_mode is not set";
    }
    elsif ( $options{format_mode} !~ /^(?:append|content\-type)$/ ) {
        croak "format_mode must be append or content-type";
    }
    else {
        $class->add_attribute(
            'api_format_mode',
            is      => 'ro',
            isa     => 'Str',
            lazy    => 1,
            default => delete $options{format_mode}
        );
    }

    if ( !$options{useragent} ) {
        _add_useragent($class);
    }
    else {
        my $method = $options{useragent};
        if ( ref $method ne 'CODE' ) {
            croak "useragent must be a CODE ref";
        }
        else {
            _add_useragent( $class, delete $options{useragent} );
        }
    }

    if ( $options{authentication} ) {
        $do_auth = delete $options{authentication};
    }

    if ( $options{authentication_method} ) {
        $auth_method = delete $options{authentication_method};
    }

    if ($options{deserialisation} ) {
        $deserialize_method = delete $options{deserialize_order};
    }else{
        MooseX::Net::API::Role::Deserialize->meta->apply($caller->meta);
    }
}

sub net_api_method {
    my $caller  = shift;
    my $name    = shift;
    my %options = (do_auth => $do_auth, @_);

    if ( !$options{params} && $options{required} ) {
        croak "you can't require a param that have not been declared";
    }

    if ( $options{required} ) {
        foreach my $required ( @{ $options{required} } ) {
            croak "$required is required but is not declared in params"
                if ( !grep { $_ eq $required } @{ $options{params} } );
        }
    }
    # XXX check method ici

    my $class = Moose::Meta::Class->initialize($caller);

    my $code;
    if ( !$options{code} ) {
        $code = sub {
            my $self = shift;
            my %args = @_;

            if ( $auth_method
                && !$self->meta->find_method_by_name($auth_method) )
            {
                croak
                    "you provided $auth_method as an authentication method, but it's not available in your object";
            }

            if ( $deserialize_method
                && !$self->meta->find_method_by_name($deserialize_method) )
            {
                croak
                    "you provided $deserialize_method for deserialisation, but the method is not available in your object";
            }

            # check if there is no undeclared param
            foreach my $arg ( keys %args ) {
                if ( !grep { $arg eq $_ } @{ $options{params} } ) {
                    croak "$arg is not declared as a param";
                }
            }

            # check if all our params declared as required are present
            foreach my $required ( @{ $options{required} } ) {
                if ( !grep { $required eq $_ } keys %args ) {
                    croak
                        "$required is declared as required, but is not present";
                }
            }

            my $path = $options{path};

            # replace all args in the url
            while ( $path =~ /\$(\w+)/ ) {
                my $match = $1;
                if ( my $value = delete $args{$match} ) {
                    $path =~ s/\$$match/$value/;
                }
            }

            # XXX improve uri building
            my $url    = $self->api_base_url . $path;
            my $format = $self->api_format();
            $url .= "." . $format if ( $self->api_format_mode() eq 'append' );
            my $uri = URI->new($url);

            my $res = _request( $self, $format, \%options, $uri, \%args );

            my $content_type = $res->headers->{"content-type"};
            $content_type =~ s/(;.+)$//;

            my @deserialize_order
                = ( $content_type, $format, keys %$list_content_type );

            my $content;
            if ($deserialize_method) {
                $content = $self->$deserialize_method( $res->content,
                    @deserialize_order );
            }
            else {
                $content = _do_deserialization( $self, $res->content,
                    @deserialize_order );
            }

            return $content if ( $res->is_success );

            my $error = MooseX::Net::API::Error->new(
                code  => $res->code,
                error => $content,
            );
            die $error;
        };
    }
    else {
        $code = $options{code};
    }

    $class->add_method(
        $name,
        MooseX::Net::API::Meta::Method->new(
            name         => $name,
            package_name => $caller,
            body         => $code,
            %options,
        ),
    );
    $class->_add_api_method($name);
}

sub _add_useragent {
    my $class = shift;
    my $code  = shift;

    if ( !$code ) {
        try { require LWP::UserAgent; }
        catch {
            croak "no useragent defined and LWP::UserAgent is not available";
        };

        $code = sub {
            my $ua = LWP::UserAgent->new();
            $ua->agent("MooseX::Net::API/$VERSION (Perl)");
            $ua->env_proxy;
            return $ua;
        };
    }
    $class->add_attribute(
        'useragent',
        is      => 'rw',
        isa     => 'Any',
        lazy    => 1,
        default => $code,
    );
}

sub _request {
    my ( $self, $format, $options, $uri, $args ) = @_;

    my $req;
    my $method = $options->{method};

    if ( $method =~ /^(?:GET|DELETE)$/ || $options->{params_in_url} ) {
        $uri->query_form(%$args);
        $req = HTTP::Request->new( $method => $uri );
    }
    elsif ( $method =~ /^(?:POST|PUT)$/ ) {
        $req = HTTP::Request->new( $method => $uri );
        my $content = _do_serialization($self, $args, $format);
        $req->content( $content );
    }
    else {
        croak "$method is not defined";
    }

    $req->header( 'Content-Type' => $list_content_type->{$format} )
        if $self->api_format_mode eq 'content-type';

    if ($do_auth) {
        if ($auth_method) {
            $req = $self->$auth_method($req);
        }
        else {
            $req = _do_authentication( $self, $req );
        }
    }

    return $self->useragent->request($req);
}

sub _do_authentication {
    my ( $caller, $req ) = @_;
    $req->headers->authorization_basic( $caller->api_username,
        $caller->api_password )
        if ( $caller->api_username && $caller->api_password );
    return $req;
}

1;

__END__

=head1 NAME

MooseX::Net::API - Easily create client for net API

=head1 SYNOPSIS

  package My::Net::API;
  use Moose;
  use MooseX::Net::API;

  # we declare an API, the base_url is http://exemple.com/api
  # the format is json and it will be happened to the query
  # You can set base_url later, calling $my_obj->api_base_url('http://..')
  net_api_declare my_api => (
    base_url   => 'http://exemple.com/api',
    format     => 'json',
    format_api => 'append',
  );

  # calling $obj->foo will call http://exemple.com/api/foo?user=$user&group=$group
  net_api_method foo => (
    description => 'this get foo',
    method      => 'GET',
    path        => '/foo/',
    params      => [qw/user group/],
    required    => [qw/user/],
  );

  # you can create your own useragent
  net_api_declare my_api => (
    ...
    useragent => sub {
      my $ua = LWP::UserAgent->new;
      $ua->agent('MyUberAgent/0.23'); 
      return $ua
    },
    ...
  );

  # if the API require authentification, the module will handle basic
  # authentication for you
  net_api_declare my_api => (
    ...
    authentication => 1,
    ...
  );

  # if the authentication is more complex, you can delegate to your own method

  1;

=head1 DESCRIPTION

MooseX::Net::API is module to help to easily create a client for a web API.
This module is heavily inspired by what L<Net::Twitter> does.

=head2 METHODS

=over 4

=item B<net_api_declare>

=over 2

=item B<base_url> (required)

The base url for all the API's calls.

=item B<format> (required, must be either xml, json or yaml)

The format for the API's calls.

=item B<format_mode> (required, must be 'append' or 'content-type')

How the format is handled. Append will add B<.json> to the query, content-type
will add the content-type information to the request header.

=item B<useragent> (optional, by default it's a LWP::UserAgent object)

=item B<authentication> (optional)

=item B<authentication> (optional)

=back

=item B<net_api_method>

=over 2

=item B<description> [string]

description of the method (this is a documentation)

=item B<method> [string]

HTTP method (GET, POST, PUT, DELETE)

=item B<path> [string]

path of the query.

If you defined your path and params like this

  net_api_method user_comments => (
    ...
    path => '/user/$user/list/$date/',
    params => [qw/user date foo bar/],
    ...
  );

and you call

  $obj->user_comments(user => 'franck', date => 'today', foo => 1, bar => 2);

the url generetad will look like

  /user/franck/list/today/?foo=1&bar=2

=item B<params> [arrayref]

list of params.

=item B<required> [arrayref]

list of required params.

=item B<authentication> (optional)

should we do an authenticated call

=item B<params_in_url> (optional)

When you do a post, the content may have to be sent as arguments in the url,
and not as content in the header.

=back

=back

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2009 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
