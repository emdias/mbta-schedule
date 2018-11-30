class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  API_BASE = 'https://api-v3.mbta.com'
end
