package Gtk2::Ex::Builder;
use strict;
use warnings;
use Sub::Call::Tail;
use Class::Accessor qw(antlers);

extends qw(Exporter);

has '_widgets', is => 'rw';

BEGIN {
    our @EXPORT__in = qw(hav meta set get on);
    our @EXPORT__out = qw(builder);
    our @EXPORT = @EXPORT__in, @EXPORT__out;
    
    my $__warn = sub {
        my $syntax = shift;
        sub { warn "you cannot call '${syntax}' directly." }
    };
    
    my $__tail = sub {
        my $func = shift;
        tail &{"$func"};
    };

    for my $syntax (@EXPORT__in) {
        *{"$syntax"} = &$__tail;
        *{"_${syntax}"} = &$__warn;
    }

    undef &__PACKAGE__::new;
}

sub builder (&) {
    my $code = shift;
    my $self = bless {
    }, __PACKAGE__;
    $code->();
    $self;
}

1;
