package MooseX::Net::API;

use URI;
use Try::Tiny;
use HTTP::Request;

use Moose;
use Moose::Exporter;

use MooseX::Net::API::Meta::Class;
use MooseX::Net::API::Meta::Method;
use MooseX::Net::API::Role::Serialize;
use MooseX::Net::API::Role::Deserialize;

our $VERSION = '0.06';

my $list_content_type = {
    'json' => 'application/json',
    'yaml' => 'text/x-yaml',
    'xml'  => 'text/xml',
};

my ( $do_auth, $base_url, $auth_method, $deserialize_method );

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

sub net_api_declare {
    my $caller  = shift;
    my $name    = shift;
    my %options = @_;

    my $class = Moose::Meta::Class->initialize($caller);

    $class->add_attribute(
        'api_base_url',
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => delete $options{base_url} || ''
    );

    if ( !$options{format} ) {
        die MooseX::Net::API::Error->new(
            reason => "format is missing in your api declaration" );
    }
    elsif ( !$list_content_type->{ $options{format} } ) {
        die MooseX::Net::API::Error->(
            reason => "format is not recognised. It must be "
                . join( " or ", keys %$list_content_type ) );
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
        die MooseX::Net::API::Error->( reason => "format_mode is not set" );
    }
    elsif ( $options{format_mode} !~ /^(?:append|content\-type)$/ ) {
        die MooseX::Net::API::Error->new(
            reason => "format_mode must be append or content-type" );
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
            die MooseX::Net::API::Error->(
                reason => "useragent must be a CODE ref" );
        }
        else {
            _add_useragent( $class, delete $options{useragent} );
        }
    }

    if ( $options{authentication} ) {
        $do_auth = delete $options{authentication};
    }

    if ( $options{username} ) {
        $class->add_attribute(
            'api_username',
            is      => 'ro',
            isa     => 'Str',
            lazy    => 1,
            default => delete $options{username}
        );
        if ( $options{password} ) {
            $class->add_attribute(
                'api_password',
                is      => 'ro',
                isa     => 'Str',
                lazy    => 1,
                default => delete $options{password}
            );
        }
    }
    if ( $options{authentication_method} ) {
        $auth_method = delete $options{authentication_method};
    }

    if ( $options{deserialisation} ) {
        $deserialize_method = delete $options{deserialize_order};
    }
    else {
        MooseX::Net::API::Role::Deserialize->meta->apply( $caller->meta );
    }

    if ( $options{serialisation} ) {
        $deserialize_method = delete $options{serialize_order};
    }
    else {
        MooseX::Net::API::Role::Serialize->meta->apply( $caller->meta );
    }
}

sub net_api_method {
    my $caller  = shift;
    my $name    = shift;
    my %options = ( authentication => $do_auth, @_ );

    if ( !$options{params} && $options{required} ) {
        die MooseX::Net::API::Error->new( reason =>
                "you can't require a param that have not been declared" );
    }

    if ( $options{required} ) {
        foreach my $required ( @{ $options{required} } ) {
            die MooseX::Net::API::Error->new( reason =>
                    "$required is required but is not declared in params" )
                if ( !grep { $_ eq $required } @{ $options{params} } );
        }
    }

    my $class = Moose::Meta::Class->initialize($caller);

    my $code;
    if ( !$options{code} ) {
        $code = sub {
            my $self = shift;
            my %args = @_;

            my $meta = $self->meta;

            if ( $auth_method && !$meta->find_method_by_name($auth_method) ) {
                die MooseX::Net::API::Error->new( reason =>
                        "you provided $auth_method as an authentication method, but it's not available in your object"
                );
            }

            if ( $deserialize_method
                && !$meta->find_method_by_name($deserialize_method) )
            {
                die MooseX::Net::API::Error->new( reason =>
                        "you provided $deserialize_method for deserialisation, but the method is not available in your object"
                );
            }

            # check if there is no undeclared param
            foreach my $arg ( keys %args ) {
                if ( !grep { $arg eq $_ } @{ $options{params} } ) {
                    die MooseX::Net::API::Error->new(
                        reason => "$arg is not declared as a param" );
                }
            }

            # check if all our params declared as required are present
            foreach my $required ( @{ $options{required} } ) {
                if ( !grep { $required eq $_ } keys %args ) {
                    die MooseX::Net::API::Error->new( reason =>
                            "$required is declared as required, but is not present"
                    );
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
            if ( $options{expected} ) {
                if ( !grep { $_ eq $res->code } @{ $options{expected} } ) {
                    die MooseX::Net::API::Error->new(
                        reason     => "unexpected code",
                        http_error => $res
                    );
                }
            }

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
                $content = $self->_do_deserialization( $res->content,
                    @deserialize_order );
            }

            return $content if ( $res->is_success );

            die MooseX::Net::API::Error->new(
                http_error => $res,
                reason     => $content
            );
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
            MooseX::Net::API::Error->new( reason =>
                    "no useragent defined and LWP::UserAgent is not available"
            );
        };

        $code = sub {
            my $ua = LWP::UserAgent->new();
            $ua->agent("MooseX::Net::API/$VERSION (Perl)");
            $ua->env_proxy;
            return $ua;
        };
    }
    $class->add_attribute(
        'api_useragent',
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
        my $content = $self->_do_serialization( $args, $format );
        $req->content($content);
    }
    else {
        die MooseX::Net::API::Error->new( reason => "$method is not defined" );
    }

    $req->header( 'Content-Type' => $list_content_type->{$format} )
        if $self->api_format_mode eq 'content-type';

    if ($do_auth || $options->{authentication}) {
        if ($auth_method) {
            $req = $self->$auth_method($req);
        }
        else {
            $req = _do_authentication( $self, $req );
        }
    }

    return $self->api_useragent->request($req);
}

sub _do_authentication {
    my ( $caller, $req ) = @_;
    $req->headers->authorization_basic( $caller->api_username,
        $caller->api_password )
        if ( $caller->api_username && $caller->api_password );
    return $req;
}

package MooseX::Net::API::Error;

use Moose;
has http_error => (
    is      => 'ro',
    isa     => 'HTTP::Response',
    handles => { http_message => 'message', http_code => 'code' }
);
has reason => ( is => 'ro', isa => 'Str|HashRef' );

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
  # You can set base_url later, calling $obj->api_base_url('http://..')
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

  my $obj = My::Net::API->new();
  $obj->api_base_url('http://...');
  $obj->foo(user => $user);

=head1 DESCRIPTION

MooseX::Net::API is module to help to easily create a client for a web API.
This module is heavily inspired by what L<Net::Twitter> does.

B<THIS MODULE IS IN ITS BETA QUALITY. THE API MAY CHANGE IN THE FUTURE>

=head2 METHODS

=over 4

=item B<net_api_declare>

  net_api_declare backtype => (
    base_url    => 'http://api....',
    format      => 'json',
    format_mode => 'append',
  );

=over 2

=item B<base_url> (required)

The base url for all the API's calls. This will add an B<api_base_url>
attribut to your class.

=item B<format> (required, must be either xml, json or yaml)

The format for the API's calls. This will add an B<api_format> attribut to
your class.

=item B<format_mode> (required, must be 'append' or 'content-type')

How the format is handled. B<append> will add B<.json> to the query,
B<content-type> will add the content-type information to the header of the
request.

=item B<useragent> (optional, by default it's a LWP::UserAgent object)

  useragent => sub {
    my $ua = LWP::UserAgent->new;
    $ua->agent( "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.1) Gecko/20061204 Firefox/2.0.0.1");
     return $ua;
  },

=item B<authentication> (optional)

This is a boolean to tell if we must authenticate to use this API.

=item B<authentication_method> (optional)

The default authentication method only set an authorization header using the
Basic Authentication Scheme. You can write your own authentication method:

  net_api_declare foo => (
    ...
    authentication_method => 'my_auth_method',
    ...
  );

  sub my_auth_method {
    my ($self, $req) = @_; #$req is an HTTP::Request object
    ...
    return $req;
  }

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
