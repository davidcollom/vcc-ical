require 'sinatra'
require_relative 'verulam_cal'

if ENV['REDIS_HOST'] != ''
  require 'lightly'
  $cache = Lightly.new life: '14h'
else
  require 'redis-store'
  $cache = Redis::Store.new host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'] || 6379, db: ENV['REDIS_DB'] || 0
end

class App < ::Sinatra::Base

  set :root, '/app/'

  set :sessions, false
  set :static, true
  set :public_folder, '/app/public/'
  set :logging, true

  get '/' do
    erb :index
  end

  get '/events' do
    content_type 'text/calendar'

    events = $cache.get("cycling:events:search") do
      puts "Downloading fresh data from VCC Website..."
      VerulamCal.events()
    end
    VerulamCal.new( events.select{|e| e['name'].include?(params[:q]||'')} ).to_ical
  end

  get '/version' do
    ENV['VERSION'] || 'Unknown'
  end


  after do
    $cache.prune
  end

end
