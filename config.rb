require_relative 'verulam_cal'

activate :dotenv

# Activate gzip compression
activate :gzip

ignore 'vendor'
ignore '.env'
ignore 'ical'

set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'img'
set :fonts_dir,  "fonts"

set :file_watcher_ignore,[
    /^bin(\/|$)/,
    /^\.bundle(\/|$)/,
    /^.c9(\/|$)/,
    /^node_modules(\/|$)/,
    /^\.sass-cache(\/|$)/,
    /^\.cache(\/|$)/,
    /^\.git(\/|$)/,
    /^\.gitignore$/,
    /\.DS_Store/,
    /^\.rbenv-.*$/,
    /^Gemfile$/,
    /^Gemfile\.lock$/,
    /~$/,
    /(^|\/)\.?#/,
    /^tmp\//
  ]

# Monkeypatching in File.exists
def File.exists? str
    File.exist? str
end

module Net::HTTPHeader
    def initialize_http_header(initheader)
        @header = {
            "User-Agent" => ["curl/8.5.0"],
            "Accept"=> ["*/*"],
        } 
    end
end

activate :data_source do |c|
    c.root  = "https://www.verulamcc.org.uk/events-calendar/month.calendar/"
    c.sources = [
        {
            alias: 'current_month',
            path: Date.today.strftime('/%Y/%m/%d/-'),
            type: :html
        },
        {
            alias: 'next_month',
            path: (Date.today.next_month).strftime('/%Y/%m/%d/-'),
            type: :html
        },
        {
            alias: 'month_after_next',
            path: (Date.today.next_month.next_month).strftime('/%Y/%m/%d/-'),
            type: :html
        }
    ]
    c.decoders = {
        html: {
          extensions: [''],
          decoder: ->(src) { VerulamCal.find_events(src) }
        }
      }
end

proxy "/events", "ical", locals: {e: VerulamCal.new( @app.data.current_month + @app.data.next_month + @app.data.month_after_next ) }

configure :server do
end

configure :development do
end

configure :production do
end

# Build-specific configuration
configure :build do
end
