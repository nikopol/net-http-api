package MooseX::Net::API::Meta::Method;

use Moose;
use MooseX::Net::API::Error;
use Moose::Util::TypeConstraints;

use MooseX::Types::Moose qw/Str Int ArrayRef/;

extends 'Moose::Meta::Method';

subtype UriPath => as 'Str' => where { $_ =~ m!^/! } =>
  message {"path must start with /"};

enum 'Method' => qw(GET POST PUT DELETE);

has description => (is => 'ro', isa => 'Str');
has method      => (is => 'ro', isa => 'Method', required => 1);
has path        => (is => 'ro', isa => 'UriPath', required => 1, coerce => 1);
has params_in_url => (is => 'ro', isa => 'Bool', default => 0);
has authentication => (is => 'ro', isa => 'Bool', required => 0, default => 0);
has expected => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Int],
    auto_deref => 1,
    required   => 0,
    predicate  => 'has_expected',
    handles    => {find_expected_code => 'grep',},
);
has params => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    required   => 0,
    default    => sub { [] },
    auto_deref => 1,
    handles    => {find_param => 'first',}
);
has required => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    default    => sub { [] },
    auto_deref => 1,
    required   => 0,
);

before wrap => sub {
    my $class = shift;
    my %args  = @_;

    $class->_validate_params_before_install(\%args);
    $class->_validate_required_before_install(\%args);
};

sub wrap {
    my $class = shift;
    my %args  = @_;

    if (!defined $args{body}) {
        my $code = sub {
            my ($self, %method_args) = @_;

            my $method =
              $self->meta->find_method_by_name($args{name})
              ->get_original_method;

            $method->_validate_before_execute(\%method_args);

            my $path = $method->_build_path(\%method_args);
            my $local_url = $method->_build_uri($self, $path);

            my $result = $self->http_request(
                $method->method => $local_url,
                $method->params_in_url, \%method_args
            );

            my $code = $result->code;

            if ($method->has_expected
                && !$method->find_expected_code(sub {/$code/}))
            {
                die MooseX::Net::API::Error->new(
                    reason     => "unexpected code",
                    http_error => $result
                );
            }

            my $content = $self->get_content($result);;

            if ($result->is_success) {
                if (wantarray) {
                    return ($content, $result);
                }
                else {
                    return $content;
                }
            }

            die MooseX::Net::API::Error->new(
                http_error => $result,
                reason     => $result->message,
            );
        };
        $args{body} = $code;
    }

    $class->SUPER::wrap(%args);
}

sub _validate_params_before_install {
    my ( $class, $args ) = @_;
    if ( !$args->{params} && $args->{required} ) {
        die MooseX::Net::API::Error->new( reason =>
                "You can't require a param that have not been declared" );
    }
}

sub _validate_required_before_install {
    my ( $class, $args ) = @_;
    if ( $args->{required} ) {
        foreach my $required ( @{ $args->{required} } ) {
            die MooseX::Net::API::Error->new( reason =>
                    "$required is required but is not declared in params" )
                if ( !grep { $_ eq $required } @{ $args->{params} } );
        }
    }
}

sub _validate_before_execute {
    my ($self, $args) = @_;
    for my $method (qw/_check_params_before_run _check_required_before_run/) {
        $self->$method($args);
    }
}

sub _check_params_before_run {
    my ($self, $args) = @_;

    # check if there is no undeclared param
    foreach my $arg (keys %$args) {
        if (!$self->find_param(sub {/$arg/})) {
            die MooseX::Net::API::Error->new(
                reason => "'$arg' is not declared as a param");
        }
    }
}

sub _check_required_before_run {
    my ($self, $args) = @_;

    # check if all our params declared as required are present
    foreach my $required ($self->required) {
        if (!grep { $required eq $_ } keys %$args) {
            die MooseX::Net::API::Error->new(reason =>
                  "'$required' is declared as required, but is not present");
        }
    }
}

sub _build_path {
    my ($self, $args) = @_;
    my $path = $self->path;

    my $max_iter = keys %$args;
    my $i        = 0;
    while ($path =~ /(?:\$|:)(\w+)/g) {
        my $match = $1;
        $i++;
        if (my $value = delete $args->{$match}) {
            $path =~ s/(?:\$|:)$match/$value/;
        }
        if ($max_iter > $i) {
            $path =~ s/(?:\$|:)(\w+)//;
        }
    }
    return $path;
}

sub _build_uri {
    my ($method, $self, $path) = @_;

    my $local_url     = $self->api_base_url->clone;
    my $path_url_base = $local_url->path;
    $path_url_base =~ s/\/$// if $path_url_base =~ m!/$!;
    $path_url_base .= $path;

    if ($self->api_format && $self->api_format_mode eq 'append') {
        my $format = $self->api_format;
        $path_url_base .= "." . $format;
    }

    $local_url->path($path_url_base);
    return $local_url;
}

1;
