#!/usr/bin/env ruby
# require 'httparty'
require 'nokogiri'
require 'digest'
require 'icalendar'
require 'icalendar/tzinfo'
require 'pry'

class VerulamCal
  # include ::HTTParty

  # # base_uri 'https://www.verulamcc.org.uk/events-calendar/year.listevents'
  # base_uri 'https://www.verulamcc.org.uk/events-calendar/month.calendar/'
  # format :html
  # headers 'Content-Type' => 'application/html', 'User-Agent': 'curl/7.64.1'
  # logger ::Logger.new STDOUT, :debug, :curl

  # TIMEZONE = 'GMT'.freeze

  DATE_REGEX = %r{(?<startDate>\w+ \d{2} \w+ \d{4})(?<startTime>\d{2}:\d{2}) - (?<endTime>\d{2}:\d{2})}.freeze
  MULTI_DATE_REGEX = %r{From:\W(?<startDate>\w+ \d{2} \w+ \d{4})\WTo:\W(:?.+)\W(?<startTime>\d{2}:\d{2})\W-\W(?<endTime>\d{2}:\d{2})}.freeze

  class << self
    # def events(options: {})
    #   # build_query = {tags: tag, limit: limit}
    #   # options.merge!( {query: build_query} )
    #   puts "Fetching Events...#{options}"
    #   resp = self.get(Date.today.strftime('/%Y/%m/%d/-'), options )
    #   return find_events(resp.body) if resp.ok?
    #   return ""
    # end

    def find_events(html)
      doc = Nokogiri::HTML(html)
      events = []

      doc.css('div.eventstyle').select{|e| !e.text.include?("CANCELED") }.each do |e|

        popup = e.css('span').first
        # Tite and data-content are embeded/escaped HTML
        title = Nokogiri::HTML(popup.attr('title')).text
        data_content = Nokogiri::HTML(popup.attr('data-content'))

        td = DATE_REGEX.match(data_content.text)
        # Assume multi date?
        td = MULTI_DATE_REGEX.match(data_content.text) if td.nil?

        url = data_content.css('a').attr('href').text || "/"

        if td.nil?
          binding.pry
          puts "Event: #{title}, unable to find date: #{data_content.text}"
          next
        end

        # binding.pry

        event = {
          'id' => Digest::SHA256.hexdigest(e.inner_html)[0..20],
          'name' => title,
          'url' => "https://www.verulamcc.org.uk#{url}",
          'eventStart' => "#{td[:startDate]} #{td[:startTime]}",
          'eventEnd' => "#{td[:startDate]} #{td[:endTime]}",
        }
        events << event
      end
      events
    end
  end

  def initialize(events)
    @cal = Icalendar::Calendar.new
    @cal.prodid = "Verulam CC iCal - by David Collom"
    @events = events
    parse_events
  end

  def parse_events
    @events.each do |event|
      puts "Added #{event} to calendar..."
      # binding.pry
      @cal.event do |e|
        e.uid         = event['id'].to_s
        e.summary     = event['name']
        e.dtstart     = Icalendar::Values::DateTime.new DateTime.parse( event['eventStart'] )#, 'tzid' => Time.now.zone
        e.dtend       = Icalendar::Values::DateTime.new calculate_end(event)#, 'tzid' => Time.now.zone
        e.url         = event['url'] unless event['url'].empty?
        e.ip_class    = "PUBLIC"
        e.append_attach Icalendar::Values::Uri.new("https://www.verulamcc.org.uk/images/VCC_web_logo.png")
        e.last_modified =  Icalendar::Values::DateTime.new DateTime.parse( Time.now.to_s )#, 'tzid' => Time.now.zone
      end
    end
  end

  def to_s
    @cal.to_ical
  end

  def to_ical
    @cal.to_ical
  end

  private

  def calculate_end(event)
    return DateTime.parse(event['eventEnd']) unless event['eventEnd'].nil?
    # If event is duration or distance related
    if event['durationInSeconds'] == 0
      puts "Assuming #{event['name']} is 1 hour long [#{event['durationInSeconds']}]"
      DateTime.parse( event['eventStart'] ).to_time + 3600 # Assume ~1 hour
    else
      # Add duration to event start
      puts "#{event['name']} is #{event['durationInSeconds']} seconds long"
      (DateTime.parse( event['eventStart'] ).to_time) + event['durationInSeconds']
    end
  end

end
