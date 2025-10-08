class Admin::BaseController < ApplicationController
  include Admin::Authentication
  layout "admin"

  helper_method :current_user
end
