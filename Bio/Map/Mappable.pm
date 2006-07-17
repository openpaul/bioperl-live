# $Id$
#
# BioPerl module for Bio::Map::Mappable
#
# Cared for by Sendu Bala <bix@sendu.me.uk>
#
# Copyright Sendu Bala
# 
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Map::Mappable - An object representing a generic map element
that can have multiple locations in several maps.

=head1 SYNOPSIS

  # a map element in two different positions on the same map
  $map1 = new Bio::Map::SimpleMap ();
  $position1 = new Bio::Map::Position (-map => $map1, $value => 100);
  $position2 = new Bio::Map::Position (-map => $map1, $value => 200);
  $mappable = new Bio::Map::Mappable (-positions => [$position1, $position2] );

  # add another position on a different map
  $map2 = new Bio::Map::SimpleMap ();
  $position3 = new Bio::Map::Position (-map => $map2, $value => 50);
  $mappable->add_position($position3);

  # get all the places our map element is found, on a particular map of interest
  foreach $pos ($mappable->get_positions($map1)) {
     print $pos->value, "\n";
  }

=head1 DESCRIPTION

This object handles the notion of a generic map element. Mappables are
entities with one or more positions on one or more maps.

This object is a pure perl implementation of L<Bio::Map::MappableI>. That
interface implements some of its own methods so check the docs there for
those.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Sendu Bala

Email bix@sendu.me.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::Map::Mappable;
use vars qw(@ISA);
use strict;
use Bio::Root::Root;
use Bio::Map::MappableI;
use Bio::Map::Relative;

@ISA = qw(Bio::Root::Root Bio::Map::MappableI);

=head2 new

 Title   : new
 Usage   : my $mappable = new Bio::Map::Mappable();
 Function: Builds a new Bio::Map::Mappable object
 Returns : Bio::Map::Mappable
 Args    : none

=cut

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    return $self;
}

=head2 in_map

 Title   : in_map
 Usage   : if ($marker->in_map($map)) {...}
 Function: Tests if this mappable is found on a specific map
 Returns : boolean
 Args    : L<Bio::Map::MapI>

=cut

sub in_map {
	my ($self, $query_map) = @_;
	$self->throw("Must supply an argument") unless $query_map;
    $self->throw("This is [$query_map], not an object") unless ref($query_map);
    $self->throw("This is [$query_map], not a Bio::Map::MapI object") unless $query_map->isa('Bio::Map::MapI');
    
    foreach my $map ($self->known_maps) {
        ($map eq $query_map) && return 1;
    }
    
    return 0;
}

=head2 Comparison methods

=cut

=head2 equals

 Title   : equals
 Usage   : if ($mappable->equals($other_mappable)) {...}
           my @equal_positions = $mappable->equals($other_mappable);
 Function: Finds the positions in this mappable that are equal to any
           comparison positions.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to compare
                    this one to (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative

=cut

sub equals {
    my $self = shift;
    return $self->_compare('equals', @_);
}

=head2 less_than

 Title   : less_than
 Usage   : if ($mappable->less_than($other_mappable)) {...}
           my @lesser_positions = $mappable->less_than($other_mappable);
 Function: Finds the positions in this mappable that are less than all
           comparison positions.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to compare
                    this one to (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative

=cut

sub less_than {
    my $self = shift;
    return $self->_compare('less_than', @_);
}

=head2 greater_than

 Title   : greater_than
 Usage   : if ($mappable->greater_than($other_mappable)) {...}
           my @greater_positions = $mappable->greater_than($other_mappable);
 Function: Finds the positions in this mappable that are greater than all
           comparison positions.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to compare
                    this one to (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative

=cut

sub greater_than {
    my $self = shift;
    return $self->_compare('greater_than', @_);
}

=head2 overlaps

 Title   : overlaps
 Usage   : if ($mappable->overlaps($other_mappable)) {...}
           my @overlapping_positions = $mappable->overlaps($other_mappable);
 Function: Finds the positions in this mappable that overlap with any
           comparison positions.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to compare
                    this one to (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative

=cut

sub overlaps {
    my $self = shift;
    return $self->_compare('overlaps', @_);
}

=head2 contains

 Title   : contains
 Usage   : if ($mappable->contains($other_mappable)) {...}
           my @container_positions = $mappable->contains($other_mappable);
 Function: Finds the positions in this mappable that contain any comparison
           positions.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to compare
                    this one to (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative

=cut

sub contains {
    my $self = shift;
    return $self->_compare('contains', @_);
}

=head2 overlapping_groups

 Title   : overlapping_groups
 Usage   : my @groups = $mappable->overlapping_groups($other_mappable);
           my @groups = Bio::Map::Mappable->overlapping_groups(\@mappables);
 Function: Look at all the positions of all the supplied mappables and group
           them according to overlap.
 Returns : array of array refs, each ref containing the Bio::Map::PositionI
           objects that overlap with each other
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to  compare
                    this one to, or an array ref of such objects (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative
           -min_pos_num => int    : the minimum number of positions that must
                                    be in a group before it will be returned
                                    [default is 1]
           -min_num => int        : the minimum number of different mappables
                                    represented by the positions in a group
                                    before it will be returned [default is 1]
           -min_percent => number : as above, but the minimum percentage of
                                    input mappables [default is 0]
           -require_self => 1|0   : require that at least one of the calling
                                    object's positions be in each group [default
                                    is 1, has no effect when the second usage
                                    form is used]
           -required => \@mappbls : require that at least one position for each
                                    mappable supplied in this array ref be in
                                    each group

=cut

sub overlapping_groups {
    my $self = shift;
    return $self->_compare('overlapping_groups', @_);
}

=head2 disconnected_intersections

 Title   : disconnected_intersections
 Usage   : @positions = $mappable->disconnected_intersections($other_mappable);
           @positions = Bio::Map::Mappable->disconnected_intersections(\@mappables);
 Function: Make the positions that are at the intersection of each group of
           overlapping positions, considering all the positions of the supplied
           mappables.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to  compare
                    this one to, or an array ref of such objects (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative
           -min_pos_num => int    : the minimum number of positions that must
                                    be in a group before the intersection will
                                    be calculated and returned [default is 1]
           -min_num => int        : the minimum number of different mappables
                                    represented by the positions in a group
                                    before the intersection will be calculated
                                    and returned [default is 1]
           -min_percent => number : as above, but the minimum percentage of
                                    input mappables [default is 0]
           -require_self => 1|0   : require that at least one of the calling
                                    object's positions be in each group [default
                                    is 1, has no effect when the second usage
                                    form is used]
           -required => \@mappbls : require that at least one position for each
                                    mappable supplied in this array ref be in
                                    each group

=cut

sub disconnected_intersections {
    my $self = shift;
    return $self->_compare('intersection', @_);
}

=head2 disconnected_unions

 Title   : disconnected_unions
 Usage   : my @positions = $mappable->disconnected_unions($other_mappable);
           my @positions = Bio::Map::Mappable->disconnected_unions(\@mappables);
 Function: Make the positions that are the union of each group of overlapping
           positions, considering all the positions of the supplied mappables.
 Returns : array of L<Bio::Map::PositionI> objects
 Args    : arg #1 = L<Bio::Map::MappableI> OR L<Bio::Map::PositionI> to  compare
                    this one to, or an array ref of such objects (mandatory)
           arg #2 = optionally, one or more of the key => value pairs below
		   -map => MapI           : a Bio::Map::MapI to only consider positions
		                            on the given map
		   -relative => RelativeI : a Bio::Map::RelativeI to calculate in terms
                                    of each Position's relative position to the
                                    thing described by that Relative
           -min_pos_num => int    : the minimum number of positions that must
                                    be in a group before the union will be
                                    calculated and returned [default is 1]
           -min_num => int        : the minimum number of different mappables
                                    represented by the positions in a group
                                    before the union will be calculated and
                                    returned [default is 1]
           -min_percent => number : as above, but the minimum percentage of
                                    input mappables [default is 0]
           -require_self => 1|0   : require that at least one of the calling
                                    object's positions be in each group [default
                                    is 0, has no effect when the second usage
                                    form is used]
           -required => \@mappbls : require that at least one position for each
                                    mappable supplied in this array ref be in
                                    each group

=cut

sub disconnected_unions {
    my $self = shift;
    return $self->_compare('union', @_);
}

# do a RangeI-related comparison by calling the corresponding PositionI method
# on all the requested Positions of our Mappables
sub _compare {
    my ($self, $method, $input, @extra_args) = @_;
    $self->throw("Must supply an object or array ref of them") unless ref($input);
    $self->throw("Wrong number of extra args (should be key => value pairs)") unless @extra_args % 2 == 0;
    my @compares = ref($input) eq 'ARRAY' ? @{$input} : ($input);
    
    my %args = (-map => undef, -relative => undef, -min_pos_num => 1, -min_num => 1,
                -min_percent => 0, -require_self => 0, -required => undef, @extra_args);
    my $map = $args{-map};
    my $rel = $args{-relative};
    my $min_pos_num = $args{-min_pos_num};
    my $min_num = $args{-min_num};
    if ($args{-min_percent}) {
        my $mn = (@compares + (ref($self) ? 1 : 0)) / 100 * $args{-min_percent};
        if ($mn > $min_num) {
            $min_num = $mn;
        }
    }
    my %required = map { $_ => 1 } $args{-required} ? @{$args{-required}} : ();
    my (@mine, @yours);
    
    if (ref($self)) {
        @mine = $self->get_positions($map);
        if ($args{-require_self}) {
            @mine > 0 or return;
            $required{$self} = 1;
        }
    }
    my @required = keys %required;
    
    foreach my $compare (@compares) {
        if ($compare->isa('Bio::Map::PositionI')) {
            push(@yours, $compare);
        }
        elsif ($compare->isa('Bio::Map::MappableI')) {
            push(@yours, $compare->get_positions($map));
        }
        else {
            $self->throw("This is [$compare], not a Bio::Map::MappableI or Bio::Map::PositionI");
        }
    }
    @yours > 0 or return;
    
    my @ok;
    SWITCH: for ($method) {
        /equals|overlaps|contains/ && do {
            @mine > 0 or return;
            foreach my $my_pos (@mine) {
                foreach my $your_pos (@yours) {
                    if ($my_pos->$method($your_pos, undef, $rel)) {
                        push(@ok, $my_pos);
                        last;
                    }
                }
            }
            last SWITCH;
        };
        /less_than|greater_than/ && do {
            @mine > 0 or return;
            if ($method eq 'greater_than') {
                my $map_start = new Bio::Map::Relative(-map => 0);
                @mine = sort { $b->end($map_start) <=> $a->end($map_start) } @mine;
                @yours = sort { $b->end($map_start) <=> $a->end($map_start) } @yours;
            }
            my $test_pos = shift(@yours);
            
            foreach my $my_pos (@mine) {
                if ($my_pos->$method($test_pos, $rel)) {
                    push(@ok, $my_pos);
                }
                else {
                    last;
                }
            }
            
            if ($method eq 'greater_than') {
                @ok = sort { $a->sortable <=> $b->sortable } @ok;
            }
            
            last SWITCH;
        };
        /overlapping_groups|intersection|union/ && do {
            my @positions = (@mine, @yours);
            my $start_pos = shift(@positions);
            my @disconnected_ranges = $start_pos->disconnected_ranges(\@positions, $rel);
            @disconnected_ranges > 0 or return;
            
            my @all_groups;
            for my $i (0..$#disconnected_ranges) {
                my $range = $disconnected_ranges[$i];
                foreach my $pos ($start_pos, @positions) {
                    if ($pos->overlaps($range, undef, $rel)) {
                        push(@{$all_groups[$i]}, $pos);
                    }
                }
            }
            
            my @groups;
            GROUPS: foreach my $group (@all_groups) {
                @{$group} >= $min_pos_num or next;
                @{$group} >= $min_num or next;
                
                my %mappables;
                foreach my $pos (@{$group}) {
                    my $mappable = $pos->element || next;
                    $mappables{$mappable} = 1;
                }
                keys %mappables >= $min_num or next;
                
                foreach my $required (@required) {
                    exists $mappables{$required} or next GROUPS;
                }
                
                my @sorted = sort { $a->sortable <=> $b->sortable } @{$group};
                push(@groups, \@sorted);
            }
            
            if ($method eq 'overlapping_groups') {
                return @groups;
            }
            else {
                foreach my $group (@groups) {
                    my $start_pos = shift(@{$group});
                    my @rel_arg = $method eq 'intersection' ? (undef, $rel) : ($rel);
                    my $result = $start_pos->$method($group, @rel_arg);
                    push(@ok, $result);
                }
            }
            
            last SWITCH;
        };
        
        $self->throw("Unknown method '$method'");
    }
    
    return @ok;
}

=head2 tuple

 Title   : tuple
 Usage   : Do Not Use!
 Function: tuple was supposed to be a private method; this method no longer
           does anything
 Returns : warning
 Args    : none
 Status  : deprecated, will be removed in next version

=cut

sub tuple {
    my $self = shift;
    $self->warn("The tuple method was supposed to be a private method, don't call it!");
}

1;
