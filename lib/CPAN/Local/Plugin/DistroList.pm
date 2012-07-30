package CPAN::Local::Plugin::DistroList;
{
  $CPAN::Local::Plugin::DistroList::VERSION = '0.001';
}

# ABSTRACT: Populate a mirror with a list of distributions

use strict;
use warnings;

use File::Path qw(make_path);
use Path::Class qw(file dir);
use File::Temp;
use URI;
use Try::Tiny;
use LWP::Simple;
use CPAN::DistnameInfo;

use Moose;
extends 'CPAN::Local::Plugin';
with 'CPAN::Local::Role::Gather';
use namespace::clean -except => 'meta';

has list =>
(
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_list',
);

has prefix =>
(
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has uris =>
(
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => { uri_list => 'elements' },
);

has cache =>
(
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has authorid =>
(
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_authorid',
);

has local =>
(
    is         => 'ro',
    isa        => 'Bool',
);

sub _build_uris
{
    my $self = shift;

    my $prefix = $self->prefix;

    my @uris;

    if ( $self->has_list )
    {
        foreach my $line ( file( $self->list )->slurp )
        {
            chomp $line;
            push @uris, $prefix . $line;
        }
    }

    return \@uris;
}

sub _build_cache
{
    return File::Temp::tempdir( CLEANUP => 1 );
}

sub gather
{
    my $self = shift;

    my @distros;

    foreach my $uri ( $self->uri_list )
    {
        my %args = $self->local
            ? ( filename => $uri )
            : ( uri => $uri, cache => $self->cache );

        $args{authorid} = $self->authorid if $self->has_authorid;
        my $distro =
            try   { $self->create_distribution(%args) }
            catch { $self->log($_) };

        push @distros, $distro if $distro;
    }

    return @distros;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::Plugin::DistroList - Populate a mirror with a list of distributions

=head1 VERSION

version 0.001

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
