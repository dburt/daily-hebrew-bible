#!/usr/bin/env ruby
#
#  Print some random verses from the Hebrew Bible (expected in hebrew_bible.txt)
#

require 'rubygems'
require 'mail'

def lines
  @lines ||= File.readlines('hebrew_bible.txt').select {|line| line =~ /\S/ }
end

VERSE_REF_PATTERN = /[A-Z][a-z]+\. \d+/

def random_verse_in(range)
  a, b = range.first, range.last
  n = rand(b - a) + a
  while lines[n] !~ VERSE_REF_PATTERN && n < b
    n += 1
  end
  n = a if n >= b
  [n, *lines[n, 2]]
end

def first_line_matching(pattern)
  lines.index(lines.grep(pattern).first)
end

start = 86  # first_line_matching /Gen. 1:1/
finish = 46661  # first_line_matching(/Credits/) - 1

break_points = [86, 11797, 20441, 30414, 35577, 46662]  # Gen, Josh, Isa, Psalms, Job, Credits

GROUPS = {
  "Torah" => (86...11797),
  "History" =>    (11797...20441),
  "Prophets" =>           (20441...30414),
  "Psalms" =>                     (30414...35577),
  "Other Writings" =>                     (35577...46662),
}

def random_verses
  verses = {}
  GROUPS.each do |group_name, range|
    verses[group_name] = random_verse_in(range)
  end
  verses.sort_by {|group_name, (n, ref, content)| n }
end

def mail_body
  verses = random_verses
  <<-END
  Here is a random selection of verses from the Hebrew Bible.
  #{verses.map {|group_name, (n, ref, content)| "#{group_name}\n#{content}" }}
  References below.
  #{ "\n" * 50 }
  References:
  #{verses.map {|group_name, (n, ref, content)| "#{group_name}: #{ref.strip} - http://biblia.com/books/niv2011/#{ref.strip.gsub(' ', '%20')}\n" }}
  END
end

puts mail_body

__END__

mail = Mail.new do
  from 'dave@burt.id.au'
  to 'ridley-daily-hebrew-bible@googlegroups.com'
  subject 'Ridley Daily Hebrew Bible'
  content_type 'text/plain; charset=UTF-8'
  body mail_body
end
mail.deliver!
