unit module Perl6::Documentable::LogTimelineSchema;

use Log::Timeline;

class Perl6::Documentable::LogTimeline::New
        does Log::Timeline::Task['Perl6::Documentable', 'Init registry', 'Process pod'] {}
