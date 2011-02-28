package Gtk2::Ex::Builder;
use strict;
use warnings;
use Sub::Call::Tail;
use Class::Accessor qw(antlers);

# ABSTRACT: Gtk2::Widget Wrapper and Gtk2 Building DSL

extends qw(Exporter);

has '_id', is => 'rw';
has '_gobj', is => 'rw';
has '_childs', is => 'rw';

BEGIN {
    our @EXPORT__in = qw(hav meta sets gets on);
    our @EXPORT__out = qw(builder);
    our @EXPORT = (@EXPORT__in, @EXPORT__out);
    
    my $__warn = sub {
        my $syntax = shift;
        sub { warn "you cannot call '${syntax}' directly." }
    };
    
    my $__tail = sub {
        my $syntax = shift;
        sub { tail &{"$syntax"} }
    };

    no strict 'refs';
    for my $syntax (@EXPORT__in) {
        *{"$syntax"} = $__tail->($syntax);
        *{"_${syntax}"} = $__warn->($syntax);
    }

    undef &__PACKAGE__::new;
}

sub builder (&) {
    my $code = shift;
    my $self = bless {
    }, __PACKAGE__;

    no warnings 'redefine';
    
    local *hav = sub {
        my ($obj) = @_;
        if (ref($obj) eq 'Gtk2::Ex::Builder') {
            $self->_gobj->add($obj->_gobj);
        }
        else {
            $self->_gobj->add($obj);
        }
    };
    local *meta = sub {
        my @args = @_;
        die "wrong number of arguments for 'meta'" unless @args % 2 == 0;
        while (my ($k, $v) = splice @args, 0, 2) {
            if ($k eq 'is') {
                $self->_id($v);
            }
            elsif ($k eq 'isa') {
                my $module = ( $v =~ m/^Gtk2::(.+)$/ ? $v : "Gtk2::$v" );
                $self->_gobj($module->new);
            }                
        }
    };
    local *sets = sub {
        my ($command, @para) = @_;
        my $method = "set_$command";
        return $self->_gobj->$method(@para);
    };
    local *gets = sub {
        my ($command) = @_;
        my $method = "get_$command";
        return $self->_gobj->$method();
    };
    local *on = sub {
        my ($signal, $code) = @_;
        $signal->_gobj->signal_connect( $signal => $code );
    };
    
    $code->();
    $self;
}

1;
