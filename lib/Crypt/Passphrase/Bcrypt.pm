package Crypt::Passphrase::Bcrypt;

use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Carp 'croak';
use Crypt::Bcrypt qw/bcrypt bcrypt_check/;

sub new {
	my ($class, %args) = @_;
	my $subtype = $args{subtype} || '2b';
	croak "Unknown subtype $subtype" unless $subtype =~ / \A 2 [abxy] \z /x;
	return bless {
		cost    => $args{cost} || 14,
		subtype => $subtype,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes(16);
	return bcrypt($password, $self->{subtype}, $self->{cost}, $salt);
}

sub needs_rehash {
	my ($self, $hash) = @_;
	my ($type, $cost) = $hash =~ / \A \$ (2[abxy]) \$ ([0-9]{2}) \$ /x or return 1;
	return 1 if $type ne $self->{subtype} || $cost < $self->{cost};
}

sub crypt_subtypes {
	return qw/2a 2b 2x 2y/;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return bcrypt_check($password, $hash);
}

1;

#ABSTRACT: A bcrypt encoder for Crypt::Passphrase

=method new(%args)

=over 4

=item * cost

This is the cost factor that is used to hash passwords.

=item * subtype

=over 4

=item * C<2b>

This is the subtype the rest of the world has been using since 2014

=item * C<2y>

This type is considered equivalent to C<2b>.

=item * C<2a>

This is an old and subtly buggy version of bcrypt. This is mainly useful for Crypt::Eksblowfish compatibility.

=item * C<2x>

This is a very broken version that is only useful for compatibility with ancient php versions.

=back

This is C<2b> by default, and you're unlikely to want to change this.

=back

=method hash_password($password)

This hashes the passwords with bcrypt according to the specified settings and a random salt (and will thus return a different result each time).

=method needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, or if any of the cost is lower that desired by the encoder.

=method crypt_types()

This class supports the following crypt types: C<2a> and C<2>.

=method verify_password($password, $hash)

This will check if a password matches a bcrypt hash.
