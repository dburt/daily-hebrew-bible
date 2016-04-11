#!/usr/bin/env ruby
#
#  Print some random verses from the Hebrew Bible (expected in hebrew_bible.txt)
#

require 'rubygems'
require 'mail'
require 'erb'
require 'date'

def lines
  @lines ||= File.readlines('hebrew_bible.txt').select {|line| line =~ /\S/ }
end

SERIAL_VERSE_START = Date.new(2015, 12, 7)

def verses
  @verses ||= begin
    [].tap do |verses|
      lines.each_with_index do |line, i|
        if lines[i] =~ VerseRef::PATTERN
          verses << verse_at_line(i)
        end
      end
    end
  end
end

def random_verse_in(range)
  a, b = range.first, range.last
  n = rand(b - a) + a
  while lines[n] !~ VerseRef::PATTERN && n < b
    n += 1
  end
  n = a if n >= b
  verse_at_line(n)
end

def verse_at_line(n)
  [n, VerseRef.new(lines[n]), lines[n + 1].strip]
end

class VerseRef
  PATTERN = /([1-4]?[A-Z][a-z]+)\. (\d+:\d+)(?: \[Eng=(\d+:\d+)\])?/
  def initialize(line)
    @match = line.strip.match(PATTERN)
  end
  def to_s
    @match[0]
  end
  def book
    @match[1]
  end
  def hebrew_verse
    @match[2]
  end
  def english_verse
    @match[3] || @match[2]
  end
end

def first_line_matching(pattern)
  lines.index(lines.grep(pattern).first)
end

def serial_verse
  n = Date.today - SERIAL_VERSE_START
  verses[n]
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
  verses = [["Serial", serial_verse]] +
    random_verses
  ERB.new(File.read("random_verse.erb")).result(binding)
end

def human_date
  (Date.today + 1).strftime("%d %b %Y")
end

## DEBUG
#puts mail_body
#__END__

mail = Mail.new do
  from 'dave@burt.id.au'
  to 'ridley-daily-hebrew-bible@googlegroups.com'
  subject "Ridley Daily Hebrew Bible for " + human_date
  content_type 'text/html; charset=UTF-8'
  body mail_body
end
mail.delivery_method :sendmail
mail.deliver!
