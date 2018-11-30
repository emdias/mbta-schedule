class DepartureBoardController < ApplicationController

  STOPS = [
    { 'stop_id' => 'place-north', 'label' => 'North Station' },
    { 'stop_id' => 'place-sstat', 'label' => 'South Station' }
    ]

  HEADERS = {
    'key' =>  ENV['API_KEY']
  }

  def index
  @board = {}
    STOPS.each do |data|
      @board[data['label']] = get_predictions(data['stop_id'])
    end
  end

  protected

  def get_predictions(stop_id)
    query = {
      'filter' => {
        'direction' => 1,  # Inbound from what I've seen
        'route_type' => 2, # Commuter Rail
        'stop' => stop_id
      },
      # including Vehicle to get the train#, Route for the more pleasant looking 'long_name', and stop t get the platform information
      'include' => 'vehicle,route,stop'
    }

    request = HTTParty.get(API_BASE + '/predictions',
      query: query,
      headers: HEADERS
      ).to_json
    json_response = JSON.parse(request)

    included = {}
    # Let's pack the included data into an easier to use hashmap
    if json_response['included']
      json_response['included'].each do |inc|
        included[inc['type']] ||= {}
        included[inc['type']][inc['id']] = inc['attributes']
      end
    end

    results = []
    json_response['data'].each do |d|
      # Ignoring any routes that don't have a vehicle present, I'm assuming they are not running right now.
      next if d['relationships']['vehicle']['data'].nil?
      this_stop_id = d['relationships']['stop']['data']['id'] # The Stop Id, so we can get the 'long_name'
      route_id = d['relationships']['route']['data']['id']

      results << {
        'status' => d['attributes']['status'],
        'arrival_time' => d['attributes']['arrival_time'],
        'departure_time' => d['attributes']['departure_time'],
        'vehicle' => (d['relationships']['vehicle']['data']['id'] rescue nil),
        'route' => (included['route'][route_id]['long_name'] rescue nil),
        'platform' => (included['stop'][this_stop_id]['platform_code'] rescue nil)
      }
    end

    results
  end
end
