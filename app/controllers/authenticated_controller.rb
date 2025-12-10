class AuthenticatedController < ApplicationController
  include Authentication

  before_action :set_current_season
end
