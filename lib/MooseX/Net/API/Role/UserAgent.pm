package MooseX::Net::API::Role::UserAgent;

# ABSTRACT: create UserAgent

use Moose::Role;
use LWP::UserAgent;

has api_useragent => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ua   = $self->meta->get_api_option('useragent');
        return $ua->() if $ua;
        $ua = LWP::UserAgent->new();
        $ua->agent(
            "MooseX::Net::API " . $MooseX::Net::API::VERSION . " (Perl)");
        $ua->env_proxy;
        return $ua;
    }
);

1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item B<api_useragent>

=back
